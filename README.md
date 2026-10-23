# Rubylode To-do for Redmine

A Redmine plugin that shows a project's tickets as a plain to-do list. Redmine 7 and up only. GPL v2 or later.
An independent plugin, not made or endorsed by the Redmine project.

Most of the time I just need a flat list: do A, do B, one nested item under B. Redmine makes every line a full
ticket form. This plugin gives each project a To-do page where every line is a ticket, so a quick list takes seconds
and anything bigger is one click away from the normal ticket edit.

![The to-do list: nested lines, progress per parent, closed lines crossed out](docs/screenshots/list.png)

## Features

- A To-do page in every project that enables the module. Every line is a ticket, nested to any depth by parent and subtask.
- Add lines in seconds: type and press Enter, keep going with Enter, nest with Tab, or paste a whole outline.
- Edit in place, with notes-app keys: Up and Down between lines, Alt+arrows to move or nest, Cmd+Enter to tick.
- A checkbox closes and reopens tickets. Closing a parent closes what is below it, after one confirmation.
- Drag a line by its grip onto another to nest it, or between lines to reorder. The order is shared by everyone on the project.
- Fold and unfold lines. Every parent shows how many of the tickets below it are closed, with a small progress bar.
- Narrow the list with Redmine's own ticket filters (status, tracker, assignee, dates, custom fields, and the rest).
  Show closed tickets is the status filter. A match whose parent is filtered out stands at the top level.
- Click a ticket number to open the ticket in a dialog, without leaving the list: the ticket's own card, with its
  Edit button, the full edit form, notes and file uploads. Right click, Edit opens the same dialog with the form showing.
  Saving closes the dialog and the list shows the change. Ctrl or Cmd click still opens the ticket page.
- Redmine's own ticket tooltip on hover and its own context menu on right click (status, assignee, edit, and more).
- Long subjects stop at two lines (Show full text shows them whole), `code`, **bold** and ~~strike~~ show as such, and the
  detail after the first dash is lighter, so the headlines scan.
- Key hints appear under a line while you edit or add one, and a Shortcuts list (or ?) shows them all.
- Everything goes through the normal ticket save, so workflow, permissions, journals and notification mails stay Redmine's.
- No settings page, no extra gem, no JavaScript library.

## Screenshots

### Edit a line in place

Click a line's text. Enter saves it and opens a new line below, as in a notes app. Key hints sit under the line.

![Editing a line, with the key hints below it](docs/screenshots/editing.png)

### Add lines

Type at the bottom, or press **+** on a line to add a line under it. Tab nests a new line under the one above, Shift+Tab
moves it back out. Paste several lines to create one ticket per line.

![Adding a line under another](docs/screenshots/adding.png)

### Redmine's ticket tooltip

Hover a line for the ticket's tooltip, shown beside the pointer.

![The ticket tooltip beside the pointer](docs/screenshots/tooltip.png)

### Redmine's own filters

The same filters as the ticket list. The page keeps them when you tick, edit or move a line.

![The filters panel above the list](docs/screenshots/filters.png)

### A ticket in a dialog

Click a ticket number. The ticket opens over the list, and Edit shows the full form. Saving brings you back to the list.

![A ticket opened in a dialog over the list](docs/screenshots/ticket-dialog.png)

### Right click

Redmine's own context menu: status, tracker, assignee, watchers, edit, copy and more.

![Redmine's context menu on a line](docs/screenshots/context-menu.png)

### Shortcuts

Press **?** (or use the Shortcuts link) for the list of keys.

![The shortcuts list](docs/screenshots/shortcuts.png)

## How it works

- Lists a project's open tickets, children nested under their parent. Show closed tickets lists them crossed out.
- Type a line at the bottom and press Enter to create a ticket (default tracker, status and priority, assigned to you).
- Click a line's text to edit the subject. Escape cancels an edit. While editing: Up and Down go to the line above or
  below, Alt+Up and Alt+Down move the line among its siblings, Alt+Right nests it under the line above, Alt+Left
  moves it back out, and Cmd+Enter (Ctrl+Enter) closes or reopens it.
- Paste several lines into the new-line box (or into a new line) to create one ticket per line. Two spaces or a tab
  nest a line under the one above, and list markers (`- `, `* `, `1. `, `- [ ] `) are dropped. Up to 100 lines.
- The checkbox closes the ticket, or reopens it. A closed line stays in place, crossed out, until you reload the page.
  Closing a parent asks once before it closes the open tickets below it, and reopening one asks the same.
- An arrow on a line with children folds it. Collapse all and Expand all are above the list. Folding is remembered per browser.
- Drag a line by its grip onto the middle of another to make it a child. Drag to the top or bottom edge of a line to
  reorder. The order is shared by everyone who can open the page.

Every change goes through the normal ticket save, so workflow, permissions, journals and notification mails behave
as for any edit.

## Requirements

- Redmine 7.0 or newer.
- A database Redmine supports (SQLite, PostgreSQL, MySQL, MariaDB). The plugin adds one small table that keeps the line order.

## Installation

The plugin's folder must be named `redmine_rubylode_todo`, the same as its id.

1. Put the plugin in your Redmine's `plugins` folder:

       cd /path/to/redmine/plugins
       git clone https://github.com/rubylode/redmine-rubylode-todo.git redmine_rubylode_todo

   Or download a release archive and unpack it as `plugins/redmine_rubylode_todo`.

2. Create the table from the Redmine folder:

       cd /path/to/redmine
       bundle exec rake redmine:plugins:migrate RAILS_ENV=production

3. Restart Redmine (Passenger, Puma, or whatever serves it).

4. Allow it, as an administrator:
   - Administration, Roles and permissions: tick **Use the to-do list** for the roles that should see the page.
   - For new projects: Administration, Settings, Projects, tick **To-do** under *Default enabled modules for new projects*.
   - For an existing project: Settings, Modules, tick **To-do**. Every project needs this once.

   To enable it on every existing project in one go, run in the Redmine folder:

       bundle exec rails runner -e production 'Project.find_each { |project| project.enable_module!(:rubylode_todo) }'

5. Open a project: a **To-do** tab now sits after **Issues**.

### Docker

Mount or copy the plugin to `/usr/src/redmine/plugins/redmine_rubylode_todo` in the container, then run the migration
inside it and restart the container:

    docker compose exec redmine bundle exec rake redmine:plugins:migrate RAILS_ENV=production
    docker compose restart redmine

If the migration complains about a missing secret key, pass the one the container already uses, for example
`docker compose exec -e SECRET_KEY_BASE="$SECRET_KEY_BASE" redmine ...`.

### Upgrading

Update the folder (`git pull`), run the migration command again (it does nothing when there is nothing new), and restart Redmine.

### Removing

    bundle exec rake redmine:plugins:migrate NAME=redmine_rubylode_todo VERSION=0 RAILS_ENV=production

Then delete the plugin folder and restart. This drops the order table. Tickets are not touched.

## Try it

A throwaway Redmine 7 runs from this folder, with the repository mounted as the plugin:

    docker compose up -d
    docker compose exec redmine bundle exec rake redmine:plugins:migrate
    docker compose restart redmine
    open http://localhost:3007

Sign in as admin (password admin, change it on first login), load the default data under Administration, create
a project, enable the To-do module and grant the permission. Wipe it with `docker compose down -v`.

## Tests

    bin/test                                      all integration tests
    bin/test test/integration/todo_moving_test.rb one file

They run in a Redmine 7 image with its test gems (`docker/test.Dockerfile`), sending the requests a browser would
send and checking the tickets and the stored order. The browser parts (drag feel, tooltip, right-click menu) have no
automated test; check them by hand in the throwaway Redmine:

- add a line, edit it, check it, uncheck it (show closed tickets to find it)
- check a parent that has open children: the confirmation names the count, Cancel changes nothing
- drag a line onto another, then to the top edge of a line, then out of its parent
- hover a line for the tooltip, right-click for the menu
- open a ticket in the dialog, change the subject, save

## License

GNU General Public License, version 2 or (at your option) any later version, the same as Redmine. See `LICENSE`.

Copyright (C) 2026 Nick Gorbikoff. Each Ruby file carries the same short notice Redmine puts on its own.
