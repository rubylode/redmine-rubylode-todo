require_relative "../test_helper"

class TodoLinesTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :trackers,
           :projects_trackers, :enabled_modules, :issue_statuses, :issues, :enumerations,
           :workflows, :journals, :journal_details

  def setup
    @project = Project.find(1)
    @project.enable_module!(:rubylode_todo)
    Role.find(1).add_permission!(:use_rubylode_todo)
    Issue.where(project_id: @project.id).delete_all
    @user = User.find_by_login("jsmith")
    log_user("jsmith", "jsmith")
  end

  test "a submitted line creates a ticket assigned to the person, with the defaults" do
    assert_difference "Issue.count", 1 do
      post "/projects/ecookbook/todo/lines", params: { subject: "Water the plants" }
    end
    assert_response :created
    ticket = Issue.order(:id).last
    assert_equal "Water the plants", ticket.subject
    assert_equal @project, ticket.project
    assert_equal @user, ticket.author
    assert_equal @user, ticket.assigned_to
    assert_equal @project.trackers.first, ticket.tracker
    assert_equal ticket.tracker.default_status, ticket.status
    assert_equal IssuePriority.default, ticket.priority
  end

  test "a blank line creates nothing" do
    assert_no_difference "Issue.count" do
      post "/projects/ecookbook/todo/lines", params: { subject: "   " }
    end
    assert_response :unprocessable_content
  end

  test "a person who may not add tickets cannot create a line" do
    Role.find(1).remove_permission!(:add_issues)
    assert_no_difference "Issue.count" do
      post "/projects/ecookbook/todo/lines", params: { subject: "Nope" }
    end
    assert_response :forbidden
  end

  test "editing a line changes the subject and writes a journal entry" do
    ticket = Issue.generate!(project_id: @project.id, subject: "Old words")
    assert_difference "Journal.count", 1 do
      patch "/projects/ecookbook/todo/lines/#{ticket.id}", params: { subject: "New words" }
    end
    assert_response :success
    assert_equal "New words", ticket.reload.subject
  end

  test "editing a line to blank changes nothing" do
    ticket = Issue.generate!(project_id: @project.id, subject: "Keep me")
    patch "/projects/ecookbook/todo/lines/#{ticket.id}", params: { subject: "" }
    assert_response :unprocessable_content
    assert_equal "Keep me", ticket.reload.subject
  end

  test "a ticket of another project cannot be edited through this list" do
    other = Issue.generate!(project_id: 3, subject: "Elsewhere")
    patch "/projects/ecookbook/todo/lines/#{other.id}", params: { subject: "Hijacked" }
    assert_response :not_found
    assert_equal "Elsewhere", other.reload.subject
  end

  def listed_ticket_ids
    get "/projects/ecookbook/todo"
    css_select("li.todo-line").map { |line| line["data-ticket-id"].to_i }
  end

  test "a line created with a parent becomes its child" do
    parent = Issue.generate!(project_id: @project.id, subject: "Plan the trip")
    post "/projects/ecookbook/todo/lines", params: { subject: "Book the train", parent_id: parent.id.to_s }
    assert_response :created
    assert_equal parent, Issue.find(response.parsed_body["id"]).parent
  end

  test "a line created in front of a sibling is listed before it" do
    first = Issue.generate!(project_id: @project.id, subject: "First")
    second = Issue.generate!(project_id: @project.id, subject: "Second")
    post "/projects/ecookbook/todo/lines", params: { subject: "Between", before_id: second.id.to_s }
    assert_response :created
    created = response.parsed_body["id"]
    assert_equal [first.id, created, second.id], listed_ticket_ids
  end

  test "a line created in front of a child of a parent is listed among that parent's children" do
    parent = Issue.generate!(project_id: @project.id, subject: "Plan the trip")
    child = Issue.generate!(project_id: @project.id, subject: "Book the train", parent_issue_id: parent.id)
    post "/projects/ecookbook/todo/lines", params: { subject: "Pack", parent_id: parent.id.to_s, before_id: child.id.to_s }
    created = response.parsed_body["id"]
    assert_equal [parent.id, created, child.id], listed_ticket_ids
  end

  test "a person who may not manage subtasks cannot create a child line" do
    Role.find(1).remove_permission!(:manage_subtasks)
    parent = Issue.generate!(project_id: @project.id, subject: "Plan the trip")
    assert_no_difference "Issue.count" do
      post "/projects/ecookbook/todo/lines", params: { subject: "Book the train", parent_id: parent.id.to_s }
    end
    assert_response :unprocessable_content
  end

  test "a line cannot be created under a ticket of another project" do
    other = Issue.generate!(project_id: 3, subject: "Elsewhere")
    assert_no_difference "Issue.count" do
      post "/projects/ecookbook/todo/lines", params: { subject: "Sneaky", parent_id: other.id.to_s }
    end
    assert_response :not_found
  end
end
