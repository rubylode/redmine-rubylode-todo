# Rubylode To-do: a to-do list over a project's tickets, for Redmine
# Copyright (C) 2026  Rubylode, Nick Gorbikoff
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

# How many open and closed tickets sit below a ticket, at any depth. Built from every visible ticket of
# the project, closed ones included, so the numbers stay right while closed tickets are hidden.
class TodoDescendantCounts
  Counts = Struct.new(:open, :closed)

  # rows: [[ticket id, parent id, closed?], ...]
  def initialize(rows)
    @closed_by_id = rows.to_h { |id, _parent_id, closed| [id, closed] }
    @child_ids_by_parent_id = rows.group_by { |_id, parent_id, _closed| parent_id }
                                  .transform_values { |group| group.map(&:first) }
  end

  def for(ticket)
    counts = Counts.new(0, 0)
    pending = @child_ids_by_parent_id.fetch(ticket.id, []).dup
    until pending.empty?
      id = pending.pop
      @closed_by_id.fetch(id) ? counts.closed += 1 : counts.open += 1
      pending.concat(@child_ids_by_parent_id.fetch(id, []))
    end
    counts
  end
end
