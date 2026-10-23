require_relative "../test_helper"

class TodoPageTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :trackers,
           :projects_trackers, :enabled_modules, :issue_statuses, :issues, :enumerations,
           :workflows

  SHOW_ANY_STATUS = { set_filter: "1", f: ["status_id"], op: { status_id: "*" }, v: { status_id: [""] } }.freeze

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
    get "/projects/ecookbook/todo", params: SHOW_ANY_STATUS
    assert_select "li.todo-line-closed[data-ticket-id='#{@closed.id}']", text: /Old chore/
  end

  test "the page carries Redmine's filter form, with the open-tickets filter set by default" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_select "form#query_form fieldset#filters #add_filter_select"
    assert_select "form#query_form input[name=set_filter][value='1']"
    assert_select "script", text: /addFilter\("status_id", "o"/
  end

  test "a filter narrows the list, and a match whose parent is filtered out stands at the top level" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: { set_filter: "1", f: ["subject"], op: { subject: "~" }, v: { subject: ["train"] } }
    assert_response :success
    assert_select "ul.todo-list > li[data-ticket-id='#{@child.id}']", text: /Book the train/
    assert_select "li[data-ticket-id='#{@sibling.id}']", count: 0
    assert_select "li[data-ticket-id='#{@parent.id}']", count: 0
    assert_select "script", text: /addFilter\("subject", "~"/
  end

  test "an invalid filter shows Redmine's error and lists nothing" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: { set_filter: "1", f: ["due_date"], op: { due_date: "><" }, v: { due_date: ["x"] } }
    assert_response :success
    assert_select ".flash.error"
    assert_select "li.todo-line", count: 0
  end

  test "the hide closed link keeps the other filters" do
    # With no status filter every status shows, so the link offers to hide the closed ones.
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: { set_filter: "1", f: ["subject"], op: { subject: "~" }, v: { subject: ["train"] } }
    link = css_select(".contextual a").find { |element| element.text =~ /Hide closed/ }
    query = Rack::Utils.parse_nested_query(URI(link["href"]).query)
    assert_equal "o", query["op"]["status_id"]
    assert_equal "~", query["op"]["subject"]
    assert_equal ["train"], query["v"]["subject"]
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
    assert_select "li[data-ticket-id='#{@parent.id}'] > div .todo-counts[title='2 open, 1 closed']", text: /1 of 3/
    assert_select "li[data-ticket-id='#{@parent.id}'] > div progress.todo-progress[max='3'][value='1']"
    assert_select "li[data-ticket-id='#{@child.id}'] > div .todo-counts[title='1 open, 0 closed']", text: /0 of 1/
    assert_select "li[data-ticket-id='#{grandchild.id}'] .todo-counts", count: 0
    assert_select "li[data-ticket-id='#{@sibling.id}'] .todo-counts", count: 0
  end

  test "the close checkbox is outside the element Redmine's context menu script treats as a row" do
    # That script ticks and unticks every checkbox inside such an element to mirror its selection.
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo", params: SHOW_ANY_STATUS
    assert_select ".hascontextmenu .todo-checkbox", count: 0
    assert_select ".hascontextmenu .todo-fold", count: 0
    assert_select ".hascontextmenu input[type=checkbox]", count: 4 # only the hidden selection box of each line
    assert_select "li[data-ticket-id='#{@closed.id}'] .todo-checkbox[checked]", count: 1
  end

  test "a subject shows its markup and the part after the first dash lighter, and keeps the raw text for editing" do
    Issue.generate!(project_id: @project.id, subject: "Fix `usb` task — **do** it, ~~not~~ later — and <b>more</b>")
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    subject = css_select(".todo-subject").find { |element| element["data-subject"].to_s.start_with?("Fix `usb`") }
    assert_equal "Fix `usb` task — **do** it, ~~not~~ later — and <b>more</b>", subject["data-subject"]
    assert_equal ["usb"], subject.css("code").map(&:text)
    assert_equal ["do"], subject.css(".todo-tail strong").map(&:text)
    assert_equal ["not"], subject.css(".todo-tail s").map(&:text)
    assert_equal 0, subject.css("b").size # the markup in the subject is shown, never run
  end

  test "every line has a grip to drag it by and labelled controls" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_select "li[data-ticket-id='#{@sibling.id}'] .todo-grip[draggable='true']"
    assert_select "li[data-ticket-id='#{@sibling.id}'] .todo-line-text[draggable]", count: 0
    assert_select "li[data-ticket-id='#{@sibling.id}'] .todo-checkbox[aria-label='Close ##{@sibling.id}']"
    assert_select "li[data-ticket-id='#{@parent.id}'] .todo-fold[aria-label^='Lines below ##{@parent.id}']"
    assert_select "[role=status][aria-live=polite]"
    assert_select "dialog.todo-shortcuts"
  end

  test "the ticket number opens the ticket in a modal, and the page loads what the ticket form needs" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_select "li[data-ticket-id='#{@sibling.id}'] a.todo-ticket-link[href='/issues/#{@sibling.id}'][data-action*='todo#openTicket']"
    assert_select "dialog.todo-ticket-dialog [data-todo-target='ticketBody']"
    assert_select "head script[src*='jstoolbar']" # the editor toolbar of the ticket form's text areas
    assert_select "head script", text: /datepickerOptions/ # the date fields
  end

  test "the full text switch says what it does" do
    log_user("jsmith", "jsmith")
    get "/projects/ecookbook/todo"
    assert_select "a[data-action*='todo#toggleFullText'][data-todo-full-label='Show full text'][data-todo-cut-label='Cut text at 2 lines']", text: "Show full text"
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
