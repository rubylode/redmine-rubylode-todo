# Listing on www.redmine.org

The text to paste at www.redmine.org, Plugins, New plugin. Redmine's "Check for updates" asks that directory about every installed plugin, so the listing must carry the same name, author and version as the plugin.

| Field | Value |
|---|---|
| Name | Rubylode To-do |
| Short description | A to-do list over a project's tickets: nested lines, checkboxes, drag and drop, keyboard editing |
| Homepage | https://github.com/rubylode/redmine-rubylode-todo |
| Compatible with | Redmine 7.0.x |
| License | GNU General Public License, version 2 or (at your option) any later version |
| Author | Rubylode |

## Notes for the first version

Version 1.2.1. A to-do list over a project's tickets: nested lines, checkboxes, drag and drop, keyboard editing. Needs Redmine 7.0 or newer. Install and settings are described in the README at https://github.com/rubylode/redmine-rubylode-todo.

## File to upload

`redmine_rubylode_todo-1.2.1.zip`, the file the GitHub release workflow publishes when a `v1.2.1` tag is pushed. Upload the same file that is attached to the GitHub release.

## Checking the result

The name, author and version in the listing must match what the plugin registers (`Rubylode To-do`, `Rubylode`, `1.2.1`). When they do, Administration, Plugins, Check for updates shows:

- a green tick: the installed version is the latest one listed on redmine.org;
- an amber warning: redmine.org lists a newer version than the installed one;
- a grey question mark: the plugin is not found, so the name or the listing needs a look.

The answer comes only from the redmine.org directory. Nothing in the plugin can change it, and it stays grey until the listing exists.
