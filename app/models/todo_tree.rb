# Arranges tickets into nested lines, siblings in the stored order. A ticket whose parent is not
# in the given set (another project, or hidden because it is closed) stands at the top level.
class TodoTree
  def initialize(tickets)
    ids = tickets.map(&:id)
    @children_by_parent_id = TodoPosition.sort(tickets).group_by do |ticket|
      ids.include?(ticket.parent_id) ? ticket.parent_id : nil
    end
  end

  def top_level_tickets
    children_of(nil)
  end

  def children_of(ticket_or_nil)
    @children_by_parent_id.fetch(ticket_or_nil&.id, [])
  end
end
