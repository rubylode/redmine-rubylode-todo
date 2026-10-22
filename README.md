# redmine-todo

A Redmine plugin that shows a project's tickets as a plain to-do list. Redmine 7 and up only. GPL v2 or later.

Most of the time I just need a flat list: do A, do B, one nested item under B. Redmine makes every line a full
ticket form. This plugin gives each project a To-do page where every line is a ticket, so a quick list takes seconds
and anything bigger is one click away from the normal ticket edit.

## What it does

- Lists a project's open tickets, children nested under their parent. A link shows closed ones crossed out.
- Type a line at the bottom and press Enter to create a ticket (default tracker, status and priority, assigned to you).
- Click a line's text to edit the subject. Enter saves it and opens a new line right below, as in a notes app. Keep
  pressing Enter to keep adding. In a new line, Tab nests it under the line above, Shift+Tab moves it back out,
  Escape (or Backspace on an empty line) stops. A + on each line adds a child under it.
- Escape cancels an edit.
- The checkbox closes the ticket, or reopens it. A closed line stays in place, crossed out, until you reload the page.
  Closing a parent asks once before it closes the open tickets below it.
- An arrow on a line with children folds it. Collapse all and Expand all are above the list. Folding is remembered per browser.
- Drag a line onto the middle of another to make it a child. Drag to the top or bottom edge of a line to reorder.
  The order is shared by everyone who can open the page.
- Hover a line for Redmine's own ticket tooltip. Right-click for Redmine's own ticket menu (status, priority,
  assignee, edit, delete).

Every change goes through the normal ticket save, so workflow, permissions, journals and notification mails behave
as for any edit. The plugin has no settings page, no extra gem and no JavaScript library.

## Install

1. Copy this folder to `plugins/redmine_todo` in your Redmine (the folder name must be `redmine_todo`).
2. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`. It creates one small table that keeps the order.
3. Restart Redmine.
4. In a project, enable the To-do module (Settings, Modules), then give a role the "Use the to-do list" permission
   (Administration, Roles and permissions).

To remove it, run `bundle exec rake redmine:plugins:migrate NAME=redmine_todo VERSION=0 RAILS_ENV=production`
and delete the folder.

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

## License

GNU General Public License, version 2 or (at your option) any later version, the same as Redmine. See `LICENSE`.
