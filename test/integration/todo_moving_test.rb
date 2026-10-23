require_relative "../test_helper"

class TodoMovingTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :trackers,
           :projects_trackers, :enabled_modules, :issue_statuses, :issues, :enumerations,
           :workflows, :journals, :journal_details

  def setup
    @project = Project.find(1)
    @project.enable_module!(:rubylode_todo)
    Role.find(1).add_permission!(:use_rubylode_todo)
    Issue.where(project_id: @project.id).delete_all
    @first = Issue.generate!(project_id: @project.id, subject: "First")
    @second = Issue.generate!(project_id: @project.id, subject: "Second")
    @third = Issue.generate!(project_id: @project.id, subject: "Third")
    log_user("jsmith", "jsmith")
  end

  def listed_ticket_ids
    get "/projects/ecookbook/todo"
    css_select("li.todo-line").map { |line| line["data-ticket-id"].to_i }
  end

  def move(ticket, parent: nil, before: nil)
    patch "/projects/ecookbook/todo/lines/#{ticket.id}/move",
          params: { parent_id: parent&.id.to_s, before_id: before&.id.to_s }
  end

  test "tickets never placed are listed by ticket id" do
    assert_equal [@first.id, @second.id, @third.id], listed_ticket_ids
  end

  test "dropping a line between two others gives it that position" do
    move(@third, before: @first)
    assert_response :success
    assert_equal [@third.id, @first.id, @second.id], listed_ticket_ids
  end

  test "the order is the same for another person" do
    move(@third, before: @first)
    post "/logout"
    Role.find(2).add_permission!(:use_rubylode_todo)
    log_user("dlopper", "foo")
    assert_equal [@third.id, @first.id, @second.id], listed_ticket_ids
  end

  test "a ticket created after the order was set is listed last" do
    move(@third, before: @first)
    newest = Issue.generate!(project_id: @project.id, subject: "Newest")
    assert_equal [@third.id, @first.id, @second.id, newest.id], listed_ticket_ids
  end

  test "dropping a line onto another makes it a child" do
    move(@second, parent: @first)
    assert_response :success
    assert_equal @first, @second.reload.parent
    assert_equal [@first.id, @second.id, @third.id], listed_ticket_ids
  end

  test "a child dropped before a top level line leaves its parent" do
    move(@second, parent: @first)
    move(@second, before: @first)
    assert_nil @second.reload.parent
    assert_equal [@second.id, @first.id, @third.id], listed_ticket_ids
  end

  test "a child can be placed before its sibling" do
    move(@second, parent: @first)
    move(@third, parent: @first, before: @second)
    assert_response :success, response.body
    assert_equal [@first.id, @third.id, @second.id], listed_ticket_ids
  end

  test "a move that would make a loop changes nothing" do
    move(@second, parent: @first)
    move(@first, parent: @second)
    assert_response :unprocessable_content
    assert_nil @first.reload.parent
  end

  test "a person who may not manage subtasks cannot nest a line" do
    Role.find(1).remove_permission!(:manage_subtasks)
    move(@second, parent: @first)
    assert_response :unprocessable_content
    assert_not_empty response.parsed_body["error"]
    assert_nil @second.reload.parent
  end

test "a person who may not edit tickets cannot move a line" do
  Role.find(1).remove_permission!(:edit_issues)
  move(@third, before: @first)
  assert_response :forbidden
  assert_equal [@first.id, @second.id, @third.id], listed_ticket_ids
end
end
