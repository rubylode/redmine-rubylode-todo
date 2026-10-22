module TodoHelper
  # How a subject is shown. The raw text stays in the line's data-subject for editing; this is display only.
  # The part after the first " — " is the line's detail and is shown lighter, so the headlines scan.
  def todo_subject_html(subject)
    headline, separator, detail = subject.partition(" — ")
    return todo_inline_markup(headline) if separator.empty?

    safe_join([todo_inline_markup(headline), tag.span("#{separator}#{todo_inline_markup(detail)}".html_safe, class: "todo-tail")])
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
