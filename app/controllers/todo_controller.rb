class TodoController < ApplicationController
  before_action :find_project_by_project_id, :authorize

  helper :issues

  def index
    @show_closed = params[:show_closed] == "1"
    tickets = Issue.visible.where(project_id: @project.id).includes(:status, :tracker, :priority, :assigned_to)
    tickets = tickets.open unless @show_closed
    @todo_tree = TodoTree.new(tickets.order(:id).to_a)
  end
end
