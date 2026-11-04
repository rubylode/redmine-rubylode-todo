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

module RubylodeTodo
  # The plugin's saved settings, the only place that knows their keys and defaults. Values are strings, as the
  # settings form saves them; an empty string means "use Redmine's own default" (the assignee defaults to "author").
  class Settings
    DEFAULTS = {
      "assignee" => "author",
      "tracker_id" => "",
      "status_id" => "",
      "priority_id" => "",
      "version_name" => "",
      "category_name" => "",
      "start_date" => "",
      "due_in_days" => ""
    }.freeze

    def self.current
      new(Setting.plugin_redmine_rubylode_todo)
    end

    def initialize(saved)
      @saved = (saved || {}).to_h.transform_keys(&:to_s)
    end

    DEFAULTS.each_key do |key|
      define_method(key) { value(key) }
    end

    private

    def value(key)
      @saved.fetch(key, DEFAULTS.fetch(key)).to_s.strip
    end
  end
end
