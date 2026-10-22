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
