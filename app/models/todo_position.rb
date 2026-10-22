# The shared order of a project's to-do lines: one row per placed ticket. Tickets without a row
# (created elsewhere, or never moved) come after the placed ones, by ticket id.
class TodoPosition < ApplicationRecord
  def self.sort(tickets)
    positions = where(issue_id: tickets.map(&:id)).pluck(:issue_id, :position).to_h
    tickets.sort_by { |ticket| [positions.fetch(ticket.id, Float::INFINITY), ticket.id] }
  end

  # Stores the given tickets' order as 1, 2, 3 ...
  def self.place(tickets_in_order)
    rows = tickets_in_order.each_with_index.map { |ticket, index| { issue_id: ticket.id, position: index + 1 } }
    upsert_all(rows, unique_by: :issue_id) if rows.any?
  end
end
