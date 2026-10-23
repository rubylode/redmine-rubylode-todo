# Changelog

## 1.1.0 (2026-10-23)

- Settings for the defaults of new lines, under Administration, Plugins, Configure: assignee (nobody, the person adding the line, or a fixed user or group), tracker, status, priority, target version and category by name, start date and due date.
- A default that doesn't fit a project or a person is skipped, and the ticket is still created.
- A disclaimer in the README.

## 1.0.0 (2026-10-23)

First release. Redmine 7.0 and newer.

- A To-do page in each project: its tickets as a nested checklist, edited in place.
- Add lines with Enter, nest them with Tab, or paste a whole outline.
- The checkbox closes and reopens tickets. Closing a parent closes what is below it, after one confirmation.
- Drag a line to nest it or reorder it. The order is shared by everyone on the project.
- Redmine's own ticket filters, tooltip and context menu.
- A ticket opens in a dialog over the list, with the full edit form.
- Tested on Redmine 7.0.2 and 7.0-stable, with Ruby 3.4 and 4.0.
