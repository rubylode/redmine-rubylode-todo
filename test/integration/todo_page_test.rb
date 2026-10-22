require_relative "../test_helper"

class TodoPageTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :trackers,
           :projects_trackers, :enabled_modules, :issue_statuses, :issues, :enumerations,
           :workflows

  def setup
    @project = Project.find(1)
    @project.enable_module!(:todo)
    Role.find(1).add_permission!(:use_todo)
    Issue.where(project_id: @project.id).delete_all
    @parent = Issue.generate!(project_id: @project.id, subject: "Plan the trip")
    @child = Issue.generate!(project_id: @project.id, subject: "Book the train", parent_issue_id: @parent.id)
    @sibling = Issue.generate!(project_id: @project.id, subject: "Buy milk")
    @closed = Issue.generate!(project_id: @project.id, subject: "Old chore", status_id: 5)
  end

  test "a member with the permission sees open tickets nested under their parent" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_response :success
    assert_select "li[data-ticket-id='#{@parent.id}'] > ul > li[data-ticket-id='#{@child.id}']", text: /Book the train/
    assert_select "ul.todo-list > li[data-ticket-id='#{@sibling.id}']", text: /Buy milk/
  end

  test "each line carries Redmine's ticket tooltip" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_select "li[data-ticket-id='#{@sibling.id}'] > div.tooltip > span.tip", text: /Buy milk/
  end

  test "closed tickets are hidden by default" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_select "li[data-ticket-id='#{@closed.id}']", count: 0
  end

  test "closed tickets show crossed out when the toggle is on" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: { show_closed: "1" }
    assert_select "li.todo-line-closed[data-ticket-id='#{@closed.id}']", text: /Old chore/
  end

  test "a ticket asked to be kept shows crossed out in its place although closed tickets are hidden" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: { keep: "#{@closed.id},999999" }
    assert_select "li.todo-line-closed[data-ticket-id='#{@closed.id}']", text: /Old chore/
    assert_select "li[data-ticket-id='#{@sibling.id}']"
  end

  test "a ticket of another project cannot be kept into the list" do
    elsewhere = Issue.generate!(project_id: 3, subject: "Elsewhere", status_id: 5)
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: { keep: elsewhere.id.to_s }
    assert_select "li[data-ticket-id='#{elsewhere.id}']", count: 0
  end

  test "a line with tickets below it shows how many are open and how many are closed, at every depth" do
    grandchild = Issue.generate!(project_id: @project.id, subject: "Check the timetable", parent_issue_id: @child.id)
    Issue.generate!(project_id: @project.id, subject: "Old booking", parent_issue_id: @parent.id, status_id: 5)
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_select "li[data-ticket-id='#{@parent.id}'] > div .todo-counts", text: "2 open, 1 closed"
    assert_select "li[data-ticket-id='#{@child.id}'] > div .todo-counts", text: "1 open, 0 closed"
    assert_select "li[data-ticket-id='#{grandchild.id}'] .todo-counts", count: 0
    assert_select "li[data-ticket-id='#{@sibling.id}'] .todo-counts", count: 0
  end

  test "the close checkbox is outside the element Redmine's context menu script treats as a row" do
    # That script ticks and unticks every checkbox inside such an element to mirror its selection.
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: { show_closed: "1" }
    assert_select ".hascontextmenu .todo-checkbox", count: 0
    assert_select ".hascontextmenu .todo-fold", count: 0
    assert_select ".hascontextmenu input[type=checkbox]", count: 4 # only the hidden selection box of each line
    assert_select "li[data-ticket-id='#{@closed.id}'] .todo-checkbox[checked]", count: 1
  end

  test "a member without the permission is refused" do
    Role.find(1).remove_permission!(:use_todo)
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_response :forbidden
  end

  test "a project without the module is refused" do
    @project.disable_module!(:todo)
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_response :forbidden
  end
end
