# Rubylode To-do: a to-do list over a project's tickets, for Redmine
# Copyright (C) 2026  Nick Gorbikoff
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
