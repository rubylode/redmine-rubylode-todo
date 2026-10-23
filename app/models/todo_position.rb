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
