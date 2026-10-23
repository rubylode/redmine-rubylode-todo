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

# Arranges tickets into nested lines, siblings in the stored order. A ticket whose parent is not
# in the given set (another project, or hidden because it is closed) stands at the top level.
class TodoTree
  def initialize(tickets, descendant_counts = nil)
    @descendant_counts = descendant_counts
    ids = tickets.map(&:id)
    @children_by_parent_id = TodoPosition.sort(tickets).group_by do |ticket|
      ids.include?(ticket.parent_id) ? ticket.parent_id : nil
    end
  end

  def descendant_counts_for(ticket)
    @descendant_counts&.for(ticket)
  end

  def top_level_tickets
    children_of(nil)
  end

  def children_of(ticket_or_nil)
    @children_by_parent_id.fetch(ticket_or_nil&.id, [])
  end
end
