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

require_relative "../test_helper"

# The one class that reads the plugin's saved settings, and the words on the settings page.
class RubylodeTodoSettingsTest < ActiveSupport::TestCase
  test "nothing saved gives the defaults, with the person adding the line as the assignee" do
    settings = RubylodeTodo::Settings.new(nil)
    assert_equal "author", settings.assignee
    assert_equal "", settings.tracker_id
    assert_equal "", settings.status_id
    assert_equal "", settings.priority_id
    assert_equal "", settings.version_name
    assert_equal "", settings.category_name
    assert_equal "", settings.start_date
    assert_equal "", settings.due_in_days
  end

  test "saved values win, with string or symbol keys" do
    settings = RubylodeTodo::Settings.new("assignee" => "", :tracker_id => "2", "version_name" => " Backlog ")
    assert_equal "", settings.assignee
    assert_equal "2", settings.tracker_id
    assert_equal "Backlog", settings.version_name
  end

  test "current reads what Redmine has saved for the plugin" do
    with_settings plugin_redmine_rubylode_todo: { "due_in_days" => "5" } do
      assert_equal "5", RubylodeTodo::Settings.current.due_in_days
    end
  end

  test "the plugin registers exactly the keys the class knows" do
    assert_equal RubylodeTodo::Settings::DEFAULTS.keys.sort, Redmine::Plugin.find(:redmine_rubylode_todo).settings[:default].keys.sort
  end

  test "every setting has a sentence case label without a final period and a hint of one or two sentences" do
    RubylodeTodo::Settings::DEFAULTS.each_key do |key|
      label = I18n.t("rubylode_todo.settings.#{key}.label", raise: true)
      hint = I18n.t("rubylode_todo.settings.#{key}.hint", raise: true)
      refute label.end_with?("."), "#{key} label ends with a period"
      assert_equal label[0], label[0].upcase, "#{key} label starts with a capital"
      assert hint.end_with?("."), "#{key} hint ends with a period"
      sentences = hint.split(/(?<=\.)\s+/)
      assert_includes 1..2, sentences.size, "#{key} hint has #{sentences.size} sentences"
    end
  end

  test "the only flat plugin keys are the ones Redmine itself reads" do
    I18n.t("label_todo") # loads the translations
    flat = I18n.backend.send(:translations)[:en].select { |key, value| !value.is_a?(Hash) && key.to_s.match?(/todo/) }.keys.map(&:to_s)
    assert_equal %w[label_todo permission_use_rubylode_todo project_module_rubylode_todo], flat.sort
  end

  test "no plugin text contains an em or en dash" do
    texts = I18n.t("rubylode_todo").to_s
    refute_match(/[–—]/, texts)
  end
end
