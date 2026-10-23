# To-do list for Redmine

Ticket #1612. Redmine 7 and up only. Status: draft, waiting for review.

TL;DR: a To-do page per project that shows its tickets as a plain nested list, and keeps every change inside Redmine's own ticket save.

## Problem

Most of the time I need a flat list: do A, do B, with one nested item under B. Redmine makes every line a full ticket
form, so a quick list takes a dozen clicks and the list itself is hard to see. Some lines deserve a full ticket, most
don't, and I want both in the same place without switching tools.

## Solution

Each project gets a To-do page. It shows the project's open tickets as a plain list, nested where tickets have parents.
Each line is a ticket and the line text is the ticket subject. Quick things are done in the list, and anything bigger
opens the normal ticket edit.

- Type a line at the bottom and press Enter to create a ticket.
- The checkbox closes the ticket and crosses the line out.
- Drag a line onto another one to make it a child, like bullets in Apple Notes. Drag between lines to reorder.
- Click the text to edit the subject in place.
- Hover a line for Redmine's own ticket tooltip.
- Right click a line for a small menu: set priority, assign to, set due date, open full edit, delete.
- Full edit opens in a modal, with all fields and file uploads.

## Acceptance behaviours

1. A person with permission opens a project's To-do page: every open ticket of that project is listed, children nested
   under their parent, in the stored order. Closed tickets stay hidden until the toggle is on.
2. The toggle shows closed tickets: they appear crossed out in their place.
3. A person without the permission, or a project without the module, asks for the page: access is refused like any
   other Redmine page.
4. A new line is submitted: a ticket is created in that project with the given subject, the default tracker, status and
   priority, assigned to the person, and it appears last in the list.
5. A blank line is submitted: nothing is created.
6. A line's text is edited: the ticket subject changes and a journal entry is written, like any edit.
7. A line is checked: the ticket gets the first closed status its workflow allows for that person, and the line is
   crossed out.
8. No closed status is allowed: the ticket is unchanged, the checkbox goes back, and the person sees why.
9. A closed line is unchecked: the ticket returns to its tracker's default status.
10. A line with open children is checked: the person is asked once, with the number of tickets that will close. On
    Cancel nothing changes. On confirm the line and all its open descendants are closed.
11. A line is dropped onto another: it becomes that line's child. If the person lacks the right to manage subtasks, or
    the move would make a loop, nothing changes and the person sees why.
12. A line is dropped between two lines: it gets that position and, if it moves out of a parent, it becomes a top level
    or sibling line as dropped.
13. The order changes: everyone who opens the page afterwards sees the same order. Lines never placed (tickets created
    elsewhere) appear after the placed ones, by ticket id.
14. The right-click menu sets priority, assignee or due date: only that field changes, as a normal ticket edit.
15. Delete is chosen: the person confirms once, and the ticket is deleted only if Redmine would allow it.
16. A change is made from the list: it goes through the normal ticket save, so validation, workflow, permissions,
    journals and notification mails behave exactly as for any edit.
17. The plugin is installed on a stock Redmine 7: it needs no other gem, no JavaScript library, no settings page and no
    configuration besides enabling the module for a project and granting the permission.

## Decisions

- One list per project, not per person. The project is the unit Redmine already uses for permissions.
- The order is shared per project and stored in one small plugin table (ticket and position), because Redmine has no
  manual order for tickets. That is the only schema change. Per-person order was rejected as more code for little gain.
- Everything goes through Redmine's ticket model, never around it, so workflow, permissions, journals and mail stay
  Redmine's. The less the plugin re-implements, the less breaks on upgrade.
- Closing picks the first closed status the workflow allows. A fixed status in settings was rejected: workflows can
  forbid it, and it would need a settings page.
- A parent with open children asks once, naming the count, then closes the whole subtree. A silent mass close was
  rejected, and a second confirmation was rejected as friction on a legitimate action.
- Notifications are not suppressed. People who rely on mail must still see changes.
- The front end is server-rendered pages and Stimulus (already in Redmine 7) with native browser drag and drop. No Turbo
  (Redmine 7 doesn't ship it), no new JavaScript, no new gems. It's the easiest to maintain and works on a stock install.
- The hover card is Redmine's own ticket tooltip, nothing extra.
- The right-click menu uses Redmine's context menu hooks, and full edit uses Redmine's own modal. Whether the ticket
  edit form loads into the modal as it is, or needs a small wrapper, gets checked in the first slice.
- Access is a project module named To-do and one permission to use the list. Each change is still checked against the
  person's ordinary rights on the ticket.
- GPL v2 or later, matching Redmine. MIT was considered, but a plugin runs inside Redmine's process, so matching is the
  safe choice. The headers get checked against Redmine's source before the license file is written.

## Test seams

One seam: the plugin's HTTP interface, tested with Redmine's integration tests (a signed in request, then the response
and the database). It covers acceptance behaviours 1 to 16. Every behaviour is a request that changes tickets or the
stored order, and the tests stay independent of how the controllers and views are organised.

A good test here signs in as a user with a role, sends the request the browser would send, and asserts the ticket
(subject, status, parent, journal count, mail count) and the stored order. Expected values are literals, never
recomputed the way the code does it. Imitate Redmine's own integration tests for issues.

Behaviour 17 and the browser-only parts (drag feel, tooltip, right-click menu, modal) are checked by a demo in the
throwaway Redmine from the compose file, with a short checklist the person can run. No browser test suite in version one.

## Out of scope

- A personal, cross-project "my to-do" page.
- Per-person ordering.
- Plugin settings, and choosing the closing status.
- Checklists inside a ticket, recurring items, reminders.
- Keyboard shortcuts beyond Enter and Escape.
- Redmine 6 and older.
- A browser test suite.

## Notes

- Redmine 7.0.2 facts relied on, read from its source and not run: Stimulus on importmap, no Turbo, jQuery and jQuery UI
  present, no sortable library, context menu hooks exist, the tooltip is plain CSS, the modal helper exists, and a status
  the workflow forbids is silently ignored by the ticket update, so the plugin must check the result.
- Redmine may refuse to close a parent through the ticket model while children are open, so the subtree close has to close
  children first. To be confirmed in the first slice.
