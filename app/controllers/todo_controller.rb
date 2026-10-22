class TodoController < ApplicationController
  before_action :find_project_by_project_id, :authorize
  before_action :find_ticket, only: %i[update close reopen move]

  helper :issues

  def index
    @show_closed = params[:show_closed] == "1"
    tickets = Issue.visible.where(project_id: @project.id)
    unless @show_closed
      # Tickets closed during this visit stay on the page, crossed out, until it is reloaded.
      kept_ids = params[:keep].to_s.split(",").map(&:to_i)
      tickets = tickets.where(id: tickets.open.pluck(:id) | kept_ids)
    end
    tickets = tickets.includes(:status, :tracker, :priority, :assigned_to)
    @todo_tree = TodoTree.new(tickets.order(:id).to_a, descendant_counts)
  end

  def create
    subject = params[:subject].to_s.strip
    return render_failure(l(:text_todo_blank_subject)) if subject.empty?
    return deny_access unless User.current.allowed_to?(:add_issues, @project)

    ticket = Issue.new(project: @project, author: User.current, subject: subject)
    tracker = ticket.allowed_target_trackers(User.current).first
    return deny_access unless tracker

    ticket.tracker = tracker
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

  def close
    open_descendants = @ticket.descendants.reject(&:closed?)
    if open_descendants.any? && params[:close_subtree] != "1"
      return render json: { open_descendant_count: open_descendants.size }, status: :conflict
    end

    failure = nil
    Issue.transaction do
      (open_descendants.reverse + [@ticket]).each do |ticket|
        ticket.reload # closing a child updates its parent, which makes the loaded copy stale
        failure = change_status(ticket) { |editable_ticket| first_allowed_closed_status(editable_ticket) }
        raise ActiveRecord::Rollback if failure
      end
    end
    failure ? render_failure(failure) : render(json: { id: @ticket.id })
  end

  # Undoes a close, including the tickets below it that are closed, after one confirmation.
  def reopen
    closed_descendants = @ticket.descendants.select(&:closed?)
    if closed_descendants.any? && params[:reopen_subtree] != "1"
      return render json: { closed_descendant_count: closed_descendants.size }, status: :conflict
    end

    failure = nil
    Issue.transaction do
      ([@ticket] + closed_descendants).each do |ticket|
        ticket.reload
        failure = change_status(ticket) { |editable_ticket| allowed_status(editable_ticket, editable_ticket.tracker.default_status) }
        raise ActiveRecord::Rollback if failure
      end
    end
    failure ? render_failure(failure) : render(json: { id: @ticket.id })
  end

  # parent_id: the line it becomes a child of (blank for top level); before_id: the sibling it goes in front of
  # (blank for last).
  def move
    return deny_access unless @ticket.attributes_editable?(User.current)

    parent = project_ticket_or_nil(params[:parent_id])
    before = project_ticket_or_nil(params[:before_id])
    return render_404 if (params[:parent_id].present? && parent.nil?) || (params[:before_id].present? && before.nil?)

    Issue.transaction do
      failure = change_parent(@ticket, parent)
      return render_failure(failure) if failure

      siblings = TodoPosition.sort(Issue.visible.where(project_id: @project.id, parent_id: parent&.id).to_a) - [@ticket]
      insert_at = before && siblings.index(before) || siblings.size
      TodoPosition.place(siblings.insert(insert_at, @ticket))
    end
    render json: { id: @ticket.id }
  end

  private

  def descendant_counts
    rows = Issue.visible.where(project_id: @project.id).joins(:status).pluck(:id, :parent_id, "issue_statuses.is_closed")
    TodoDescendantCounts.new(rows)
  end

  def project_ticket_or_nil(id)
    Issue.visible.where(project_id: @project.id).find_by(id: id) if id.present?
  end

  # Returns an error message, or nil when the ticket now has the given parent.
  def change_parent(ticket, parent)
    return nil if ticket.parent_id == parent&.id

    ticket.init_journal(User.current)
    ticket.safe_attributes = { "parent_issue_id" => parent&.id.to_s }
    return l(:text_todo_no_subtask_right) unless ticket.parent_issue_id == parent&.id
    return nil if ticket.save

    ticket.errors.full_messages.to_sentence
  end

  # Sets the status the block picks, through the normal ticket save. Returns an error message, or nil on success.
  # Redmine silently ignores a status the workflow forbids, so the result is checked.
  def change_status(ticket)
    return l(:notice_not_authorized) unless ticket.visible?(User.current) && ticket.attributes_editable?(User.current)

    status = yield ticket
    return l(:text_todo_no_status_allowed, ticket: "##{ticket.id}") unless status

    ticket.init_journal(User.current)
    ticket.safe_attributes = { "status_id" => status.id.to_s }
    return l(:text_todo_no_status_allowed, ticket: "##{ticket.id}") unless ticket.status_id == status.id
    return nil if ticket.save

    ticket.errors.full_messages.to_sentence
  end

  def first_allowed_closed_status(ticket)
    ticket.new_statuses_allowed_to(User.current).find(&:is_closed?)
  end

  def allowed_status(ticket, status)
    status if status && ticket.new_statuses_allowed_to(User.current).include?(status)
  end

  def find_ticket
    @ticket = Issue.visible.where(project_id: @project.id).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def render_failure(message)
    render json: { error: message }, status: :unprocessable_content
  end
end
