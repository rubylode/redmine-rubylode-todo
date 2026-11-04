# Changelog

All notable changes to this plugin. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.2.1] - 2026-11-04

### Changed

- Needs Redmine 7.0 or newer again. Version 1.2.0 said Redmine 6.0 and newer, which was wrong: the to-do page runs on the
  Stimulus setup that Redmine 7 ships, and older versions do not have it. The page would show there without working
  controls. The plugin's own tests do not run the script, so they passed on 6.0 and 6.1 all the same. No code changed in this version.

## [1.2.0] - 2026-11-04

### Changed

- Runs on Redmine 6.0 and newer. The plugin's own tests pass unchanged on those versions; no code changed.

## [1.1.2] - 2026-11-03

### Added

- A Rubylode thumbnail at the top of the README.

### Changed

- The README is plainer and has a licence section.
- The changelog entries are plainer.
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

[Unreleased]: https://github.com/rubylode/redmine-rubylode-todo/compare/v1.1.0...main
[1.1.0]: https://github.com/rubylode/redmine-rubylode-todo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/rubylode/redmine-rubylode-todo/releases/tag/v1.0.0
