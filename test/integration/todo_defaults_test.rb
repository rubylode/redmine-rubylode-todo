# Rubylode To-do: a to-do list over a project's tickets, for Redmine
# Copyright (C) 2026  Nick Gorbikoff
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require_relative "../test_helper"

# The defaults a new line gets, set on the plugin's settings page. A default that cannot be applied is skipped,
# and the ticket is still created.
class TodoDefaultsTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :trackers,
           :projects_trackers, :enabled_modules, :issue_statuses, :issues, :enumerations,
           :workflows

  def setup
    @project = Project.find(1)
    @project.enable_module!(:rubylode_todo)
    Role.find(1).add_permission!(:use_rubylode_todo)
    Issue.where(project_id: @project.id).delete_all
    @user = User.find_by_login("jsmith")
    @colleague = User.find_by_login("dlopper")
  end

  def add_line(settings = {})
    unless @signed_in
      log_user("jsmith", "jsmith")
      @signed_in = true
    end
    ticket = nil
    with_settings plugin_redmine_rubylode_todo: settings do
      assert_difference "Issue.count", 1 do
        post "/projects/ecookbook/todo/lines", params: { subject: "Water the plants" }
      end
      assert_response :created
      ticket = Issue.order(:id).last
    end
    ticket
  end

  test "with no settings saved the person adding the line is the assignee, as before" do
    assert_equal @user, add_line({}).assigned_to
  end

  test "assignee set to nobody leaves the ticket unassigned" do
    assert_nil add_line("assignee" => "").assigned_to
  end

  test "a fixed assignee who can be assigned in the project gets the ticket" do
    assert_equal @colleague, add_line("assignee" => @colleague.id.to_s).assigned_to
  end

  test "a fixed group gets the ticket when Redmine allows assigning to groups, and is skipped when it does not" do
    group = Group.find(11)
    Member.create!(project: @project, principal: group, roles: [Role.find(2)])
    with_settings issue_group_assignment: "1" do
      assert_equal group, add_line("assignee" => group.id.to_s).assigned_to
    end
    with_settings issue_group_assignment: "0" do
      assert_nil add_line("assignee" => group.id.to_s).assigned_to
    end
  end

  test "a fixed assignee who cannot be assigned in the project is skipped and the ticket is still created" do
    outsider = User.find_by_login("rhill")
    assert_nil add_line("assignee" => outsider.id.to_s).assigned_to
  end

  test "the person adding the line keeps the ticket even when their role is not assignable, as Redmine allows an author" do
    Role.find(1).update!(assignable: false)
    assert_equal @user, add_line("assignee" => "author").assigned_to
  end

  test "a tracker the project allows is applied" do
    assert_equal Tracker.find(2), add_line("tracker_id" => "2").tracker
  end

  test "a tracker the project does not use is skipped" do
    elsewhere = Tracker.create!(name: "Elsewhere", default_status: IssueStatus.find(1))
    assert_equal @project.trackers.first, add_line("tracker_id" => elsewhere.id.to_s).tracker
  end

  test "a status the workflow allows for a new ticket is applied" do
    assert_equal IssueStatus.find(2), add_line("status_id" => "2").status
  end

  test "a status the workflow does not allow for a new ticket is skipped" do
    WorkflowTransition.where(role_id: 1).delete_all
    ticket = add_line("status_id" => "2")
    assert_equal ticket.tracker.default_status, ticket.status
  end

  test "an active priority is applied and an inactive one is skipped" do
    high = IssuePriority.find_by(name: "High")
    assert_equal high, add_line("priority_id" => high.id.to_s).priority

    high.update!(active: false)
    assert_equal IssuePriority.default, add_line("priority_id" => high.id.to_s).priority
  end

  test "an open version with the given name is applied" do
    version = Version.create!(project: @project, name: "Backlog", status: "open")
    assert_equal version, add_line("version_name" => "Backlog").fixed_version
  end

  test "a closed version, or a name the project does not have, is skipped" do
    Version.create!(project: @project, name: "Shipped", status: "closed")
    assert_nil add_line("version_name" => "Shipped").fixed_version
    assert_nil add_line("version_name" => "No such version").fixed_version
  end

  test "a category with the given name is applied" do
    category = IssueCategory.create!(project: @project, name: "Chores")
    assert_equal category, add_line("category_name" => "Chores").category
  end

  test "a category the project does not have is skipped" do
    assert_nil add_line("category_name" => "Chores").category
  end

  test "the start date can be today and the due date days after today" do
    ticket = add_line("start_date" => "today", "due_in_days" => "3")
    assert_equal @user.today, ticket.start_date
    assert_equal @user.today + 3, ticket.due_date
  end

  test "a due date alone, or an unusable number of days, is handled" do
    assert_equal @user.today + 7, add_line("due_in_days" => "7").due_date
    assert_nil add_line("due_in_days" => "soon").due_date
    assert_nil add_line("due_in_days" => "-2").due_date
  end

  test "a field the tracker has disabled is skipped" do
    tracker = @project.trackers.first
    tracker.update!(core_fields: Tracker::CORE_FIELDS - ["category_id"])
    IssueCategory.create!(project: @project, name: "Chores")
    assert_nil add_line("category_name" => "Chores").category
  end

  test "a field the role may not edit on a new ticket is skipped" do
    # A new ticket starts in the tracker's default status, and the rule is keyed by that status.
    tracker = @project.trackers.first
    WorkflowPermission.create!(tracker_id: tracker.id, old_status_id: tracker.default_status_id, role_id: 1,
                               field_name: "due_date", rule: "readonly")
    assert_nil add_line("due_in_days" => "3").due_date
  end

  test "the settings page shows the defaults and saves them" do
    log_user("admin", "admin")
    get "/settings/plugin/redmine_rubylode_todo"
    assert_response :success
    assert_select "select[name='settings[assignee]']"
    assert_select "select[name='settings[tracker_id]']"
    assert_select "select[name='settings[status_id]']"
    assert_select "select[name='settings[priority_id]']"
    assert_select "input[name='settings[version_name]']"
    assert_select "input[name='settings[category_name]']"
    assert_select "select[name='settings[start_date]']"
    assert_select "input[name='settings[due_in_days]']"

    post "/settings/plugin/redmine_rubylode_todo",
         params: { settings: { assignee: "", tracker_id: "2", version_name: "Backlog", due_in_days: "5" } }
    assert_response :redirect
    saved = Setting.plugin_redmine_rubylode_todo
    assert_equal "", saved["assignee"]
    assert_equal "2", saved["tracker_id"]
    assert_equal "Backlog", saved["version_name"]
    assert_equal "5", saved["due_in_days"]
  end

  test "only an administrator reaches the settings page" do
    log_user("jsmith", "jsmith")
    get "/settings/plugin/redmine_rubylode_todo"
    assert_response :forbidden
  end
end
