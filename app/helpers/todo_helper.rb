module TodoHelper
  # How a subject is shown. The raw text stays in the line's data-subject for editing; this is display only.
  # The part after the first " — " is the line's detail and is shown lighter, so the headlines scan.
  def todo_subject_html(subject)
    headline, separator, detail = subject.partition(" — ")
    return todo_inline_markup(headline) if separator.empty?

    safe_join([todo_inline_markup(headline), tag.span("#{separator}#{todo_inline_markup(detail)}".html_safe, class: "todo-tail")])
  end

  # The filters as request parameters, so a link or a refresh keeps them. An empty f[] means "no filters":
  # without it Redmine falls back to open tickets.
  def todo_query_params(query)
    params = query.as_params.slice(:f, :op, :v, :set_filter)
    params[:f] ||= [""]
    params
  end

  # The same filters with the status filter set to open tickets, or to any status.
  def todo_status_params(query, show_closed)
    params = todo_query_params(query)
    params[:f] = ["status_id"] + params[:f].reject { |field| field == "" || field == "status_id" }
    params[:op] = (params[:op] || {}).merge("status_id" => show_closed ? "*" : "o")
    params[:v] = (params[:v] || {}).merge("status_id" => [""])
    params
  end

  private

  # `code`, **bold** and ~~strike~~. The text is escaped first, so nothing in a subject can add other markup.
  def todo_inline_markup(text)
    ERB::Util.html_escape(text).to_str
      .gsub(/`([^`]+)`/) { "<code>#{$1}</code>" }
      .gsub(/\*\*([^*]+)\*\*/) { "<strong>#{$1}</strong>" }
      .gsub(/~~([^~]+)~~/) { "<s>#{$1}</s>" }
      .html_safe
  end
end
