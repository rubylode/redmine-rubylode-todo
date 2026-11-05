# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [2.0.0] - 2026-11-04

Brings the plugin to the Rubylode plugin standard. The To-do page, its routes and the JSON endpoints behave as before.

### Changed

- Renamed settings keys: none. `assignee`, `tracker_id`, `status_id`, `priority_id`, `version_name`, `category_name`,
  `start_date` and `due_in_days` keep their names and values.
- Migrations: none added. Settings saved under 1.x keep working, so no data moves.
- A class, `RubylodeTodo::Settings`, now reads the saved settings and holds their defaults.
- All text moved under one locale root, `rubylode_todo`. The settings page takes its labels and hints from
  `rubylode_todo.settings.<key>.label` and `.hint`. Only `label_todo`, `project_module_rubylode_todo` and
  `permission_use_rubylode_todo` stay flat, because Redmine reads them by those names.
- Wording: the closing and reopening confirmations say "ticket" or "tickets" by count and no longer ask "Continue?",
  "Tab nests it under #id" replaces "Tab nest under #id", and "Loading the ticket" lost its ellipsis. The one-line hints
  on the settings page now start with what the setting does and end in a period.
- Version 2.0.0 still needs Redmine 7.0 or newer.

### What to do when you upgrade

1. Pull the new version into `plugins/redmine_rubylode_todo`.
2. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`. It finds nothing new.
3. Restart Redmine.
4. If you translated `config/locales/en.yml`, move your strings under the `rubylode_todo` root; the old flat `label_todo_*` and
   `text_todo_*` keys are gone.

### Fixed

- The README said the text after the first "dash" goes lighter. It is the first em dash, and only that one.
- The original design document said the plugin has no settings page. It has had one since 1.1.0.

### Added

- Unit tests for the settings class and the settings page wording.

## [1.2.1] - 2026-11-04

### Changed

- Needs Redmine 7.0 or newer again. Version 1.2.0 said 6.0, which was wrong: the page needs the Stimulus setup Redmine 7
  ships, and on older versions it shows without working controls. The tests don't run the script, so they passed there anyway.
  No code changed.

## [1.2.0] - 2026-11-04

### Changed

- Runs on Redmine 6.0 and newer. The plugin's own tests pass unchanged on those versions; no code changed.

## [1.1.2] - 2026-11-03

### Added

- A Rubylode thumbnail at the top of the README.

### Changed

- The README is shorter and has a License section.
- Reworded the changelog entries.
- The release build writes the checksum file inside the build step.

## [1.1.1] - 2026-11-02

### Added

- The plugins page in Administration shows the project address.
- The plugin's name, author and version match the redmine.org listing, so "Check for updates" can find it. The listing text is in `docs/redmine-org-listing.md`.

### Changed

- The README said the plugin had no settings page. It has one.

## [1.1.0] - 2026-10-23

### Added

- Settings for the defaults of new lines, under Administration, Plugins, Configure: assignee (nobody, the person adding the line, or a fixed user or group), tracker, status, priority, target version and category by name, start date and due date.
- A default that doesn't fit a project or a person is skipped, and the ticket is still created.
- A disclaimer in the README.

## [1.0.0] - 2026-10-23

First release. Redmine 7.0 and newer.

### Added

- A To-do page in each project: its tickets as a nested checklist, edited in place.
- Add lines with Enter, nest them with Tab, or paste a whole outline.
- The checkbox closes and reopens tickets. Closing a parent closes what is below it, after one confirmation.
- Drag a line to nest it or reorder it. The order is shared by everyone on the project.
- Redmine's own ticket filters, tooltip and context menu.
- A ticket opens in a dialog over the list, with the full edit form.
- Tested on Redmine 7.0.2 and 7.0-stable, with Ruby 3.4 and 4.0.

[Unreleased]: https://github.com/rubylode/redmine-rubylode-todo/compare/v2.0.0...main
[2.0.0]: https://github.com/rubylode/redmine-rubylode-todo/compare/v1.2.1...v2.0.0
[1.1.0]: https://github.com/rubylode/redmine-rubylode-todo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rubylode/redmine-rubylode-todo/releases/tag/v1.0.0
