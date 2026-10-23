# Rubylode To-do: a to-do list over a project's tickets, for Redmine
# Copyright (C) 2026  Rubylode, Nick Gorbikoff
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

class TodoClosingTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :trackers,
           :projects_trackers, :enabled_modules, :issue_statuses, :issues, :enumerations,
           :workflows, :journals, :journal_details

  def setup
    @project = Project.find(1)
    @project.enable_module!(:rubylode_todo)
    Role.find(1).add_permission!(:use_rubylode_todo)
    Issue.where(project_id: @project.id).delete_all
    @ticket = Issue.generate!(project_id: @project.id, subject: "Pay the bill")
    log_user("jsmith", "jsmith")
  end

  test "checking a line gives the ticket a closed status its workflow allows" do
    assert_difference "Journal.count", 1 do
      post "/projects/ecookbook/todo/lines/#{@ticket.id}/close"
    end
    assert_response :success
    assert @ticket.reload.closed?
  end

  test "when no closed status is allowed the ticket is unchanged and the reason is returned" do
    WorkflowTransition.where(role_id: 1).delete_all
    post "/projects/ecookbook/todo/lines/#{@ticket.id}/close"
    assert_response :unprocessable_content
    assert_not_empty response.parsed_body["error"]
    assert_not @ticket.reload.closed?
  end

  test "unchecking a closed line returns the ticket to its tracker's default status" do
    post "/projects/ecookbook/todo/lines/#{@ticket.id}/close"
    delete "/projects/ecookbook/todo/lines/#{@ticket.id}/close"
    assert_response :success
    assert_equal @ticket.tracker.default_status, @ticket.reload.status
  end

  test "checking a parent with open children asks first and changes nothing" do
    child = Issue.generate!(project_id: @project.id, subject: "Find the bill", parent_issue_id: @ticket.id)
    grandchild = Issue.generate!(project_id: @project.id, subject: "Look in the drawer", parent_issue_id: child.id)
    post "/projects/ecookbook/todo/lines/#{@ticket.id}/close"
    assert_response :conflict
    assert_equal 2, response.parsed_body["open_descendant_count"]
    assert_not @ticket.reload.closed?
    assert_not grandchild.reload.closed?
  end

  test "confirming closes the whole subtree" do
    child = Issue.generate!(project_id: @project.id, subject: "Find the bill", parent_issue_id: @ticket.id)
    grandchild = Issue.generate!(project_id: @project.id, subject: "Look in the drawer", parent_issue_id: child.id)
    post "/projects/ecookbook/todo/lines/#{@ticket.id}/close", params: { close_subtree: "1" }
    assert_response :success
    assert_equal [true, true, true], [@ticket, child, grandchild].map { |ticket| ticket.reload.closed? }
  end

  test "a subtree that cannot be closed completely is left as it was" do
    child = Issue.generate!(project_id: @project.id, subject: "Find the bill", parent_issue_id: @ticket.id)
    blocker = Issue.generate!(project_id: @project.id, subject: "Blocker")
    IssueRelation.create!(issue_from: blocker, issue_to: child, relation_type: "blocks")
    post "/projects/ecookbook/todo/lines/#{@ticket.id}/close", params: { close_subtree: "1" }
    assert_response :unprocessable_content
    assert_equal [false, false], [@ticket, child].map { |ticket| ticket.reload.closed? }
  end

test "a person who may not edit tickets cannot close one" do
  Role.find(1).remove_permission!(:edit_issues)
  post "/projects/ecookbook/todo/lines/#{@ticket.id}/close"
  assert_response :unprocessable_content
  assert_not @ticket.reload.closed?
end

def close_family
    child = Issue.generate!(project_id: @project.id, subject: "Find the bill", parent_issue_id: @ticket.id)
    grandchild = Issue.generate!(project_id: @project.id, subject: "Look in the drawer", parent_issue_id: child.id)
    post "/projects/ecookbook/todo/lines/#{@ticket.id}/close", params: { close_subtree: "1" }
    [child, grandchild]
  end

  test "unchecking a parent whose children are closed asks first and changes nothing" do
    child, grandchild = close_family
    delete "/projects/ecookbook/todo/lines/#{@ticket.id}/close"
    assert_response :conflict
    assert_equal 2, response.parsed_body["closed_descendant_count"]
    assert_equal [true, true, true], [@ticket, child, grandchild].map { |ticket| ticket.reload.closed? }
  end

  test "confirming reopens the parent and every closed ticket below it" do
    child, grandchild = close_family
    delete "/projects/ecookbook/todo/lines/#{@ticket.id}/close", params: { reopen_subtree: "1" }
    assert_response :success
    assert_equal [false, false, false], [@ticket, child, grandchild].map { |ticket| ticket.reload.closed? }
  end

  test "a subtree that cannot be reopened completely is left as it was" do
    child, grandchild = close_family
    grandchild.reload.update_columns(tracker_id: 2) # a tracker whose workflow lets nobody reopen
    WorkflowTransition.where(role_id: 1, tracker_id: 2).delete_all
    delete "/projects/ecookbook/todo/lines/#{@ticket.id}/close", params: { reopen_subtree: "1" }
    assert_response :unprocessable_content
    assert_equal [true, true, true], [@ticket, child, grandchild].map { |ticket| ticket.reload.closed? }
  end
end
