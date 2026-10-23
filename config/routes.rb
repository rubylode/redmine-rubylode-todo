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

get "projects/:project_id/todo", to: "todo#index", as: :project_todo
post "projects/:project_id/todo/lines", to: "todo#create", as: :project_todo_lines
patch "projects/:project_id/todo/lines/:id", to: "todo#update", as: :project_todo_line
post "projects/:project_id/todo/lines/:id/close", to: "todo#close", as: :project_todo_line_close
delete "projects/:project_id/todo/lines/:id/close", to: "todo#reopen"
patch "projects/:project_id/todo/lines/:id/move", to: "todo#move", as: :project_todo_line_move
