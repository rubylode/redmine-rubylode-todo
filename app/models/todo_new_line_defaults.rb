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

# The defaults a new line gets, read from the plugin's settings. A default that does not fit this ticket or this
# person is skipped, so adding a line never fails over one.
class TodoNewLineDefaults
  def initialize(settings)
    @settings = (settings || {}).to_h.transform_keys(&:to_s)
  end

  # Fills the given new ticket. The tracker and status come first, because what a person may edit depends on them.
  def apply(ticket, user)
    apply_tracker(ticket, user)
    apply_status(ticket, user)
    editable = ticket.safe_attribute_names(user)
    apply_priority(ticket, editable)
    apply_assignee(ticket, user, editable)
    apply_version(ticket, editable)
    apply_category(ticket, editable)
    apply_dates(ticket, user, editable)
  end

  private

  def apply_tracker(ticket, user)
    tracker = ticket.allowed_target_trackers(user).find { |candidate| candidate.id == number(:tracker_id) }
    return unless tracker

    ticket.tracker = tracker
    ticket.status = tracker.default_status
  end

  def apply_status(ticket, user)
    return unless ticket.safe_attribute_names(user).include?("status_id")

    status = ticket.new_statuses_allowed_to(user).find { |candidate| candidate.id == number(:status_id) }
    ticket.status = status if status
  end

  def apply_priority(ticket, editable)
    return unless editable.include?("priority_id")

    priority = IssuePriority.active.find_by(id: number(:priority_id))
    ticket.priority = priority if priority
  end

  # "author" is the person adding the line, anything else is the id of a user or group, blank is nobody.
  # Redmine decides who can be assigned; a ticket's author always can.
  def apply_assignee(ticket, user, editable)
    return unless editable.include?("assigned_to_id")

    wanted = @settings.fetch("assignee", "author").to_s
    candidate = wanted == "author" ? user : Principal.find_by(id: number(:assignee))
    ticket.assigned_to = candidate if candidate && ticket.assignable_users.include?(candidate)
  end

  def apply_version(ticket, editable)
    name = @settings["version_name"].to_s.strip
    return if name.empty? || !editable.include?("fixed_version_id")

    version = ticket.assignable_versions.find { |candidate| candidate.name.casecmp?(name) }
    ticket.fixed_version = version if version
  end

  def apply_category(ticket, editable)
    name = @settings["category_name"].to_s.strip
    return if name.empty? || !editable.include?("category_id")

    category = ticket.project.issue_categories.find { |candidate| candidate.name.casecmp?(name) }
    ticket.category = category if category
  end

  def apply_dates(ticket, user, editable)
    ticket.start_date = user.today if @settings["start_date"] == "today" && editable.include?("start_date")

    days = number(:due_in_days)
    ticket.due_date = user.today + days if days && days >= 0 && editable.include?("due_date")
  end

  def number(key)
    Integer(@settings[key.to_s].to_s.strip, exception: false)
  end
end
