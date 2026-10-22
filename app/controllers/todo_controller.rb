class TodoController < ApplicationController
  before_action :find_project_by_project_id, :authorize
  before_action :find_ticket, only: %i[update]

  helper :issues

  def index
    @show_closed = params[:show_closed] == "1"
    tickets = Issue.visible.where(project_id: @project.id).includes(:status, :tracker, :priority, :assigned_to)
    tickets = tickets.open unless @show_closed
    @todo_tree = TodoTree.new(tickets.order(:id).to_a)
  end

  def create
    subject = params[:subject].to_s.strip
    return render_failure(l(:text_todo_blank_subject)) if subject.empty?
    return deny_access unless User.current.allowed_to?(:add_issues, @project)

    ticket = Issue.new(project: @project, author: User.current, subject: subject)
    ticket.tracker = @project.trackers.first
    ticket.status = ticket.tracker.default_status
    ticket.priority = IssuePriority.default || IssuePriority.active.first
    ticket.assigned_to = User.current if ticket.assignable_users.include?(User.current)
    if ticket.save
      render json: { id: ticket.id }, status: :created
    else
      render_failure(ticket.errors.full_messages.to_sentence)
    end
  end

  def update
    return deny_access unless @ticket.attributes_editable?(User.current)

    @ticket.init_journal(User.current)
    @ticket.safe_attributes = { "subject" => params[:subject].to_s.strip }
    if @ticket.save
      render json: { id: @ticket.id }
    else
      render_failure(@ticket.errors.full_messages.to_sentence)
    end
  end

  private

  def find_ticket
    @ticket = Issue.visible.where(project_id: @project.id).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_failure(message)
    render json: { error: message }, status: :unprocessable_content
  end
end
