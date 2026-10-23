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

require "redmine"

Redmine::Plugin.register :redmine_rubylode_todo do
  name "Rubylode To-do"
  author "Rubylode"
  author_url "https://github.com/rubylode"
  description "A to-do list over a project's tickets: nested lines, checkboxes, drag and drop, keyboard editing"
  version "1.1.0"
  requires_redmine version_or_higher: "7.0.0"

  project_module :rubylode_todo do
    permission :use_rubylode_todo, { todo: %i[index create update close reopen move] }
  end

  menu :project_menu, :rubylode_todo, { controller: "todo", action: "index" },
       caption: :label_todo, after: :issues, param: :project_id

  # The defaults a new line gets. Saved from Administration, Plugins, Configure.
  settings default: { "assignee" => "author", "tracker_id" => "", "status_id" => "", "priority_id" => "",
                      "version_name" => "", "category_name" => "", "start_date" => "", "due_in_days" => "" },
           partial: "settings/rubylode_todo"
end
