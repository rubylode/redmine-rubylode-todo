# To-do list for Redmine

Ticket #1612. Redmine 7 and up only. Status: draft, waiting for review.

## Problem

Most of the time I need a flat list: do A, do B, with one nested item under B. Redmine makes every line a full ticket
form, so a quick list takes a dozen clicks and the list itself is hard to see. Some lines deserve a full ticket, most do
not, and I want both in the same place without switching tools.

## Solution

Each project gets a To-do page. It shows the project's open tickets as a plain list, nested where tickets have parents.
Each line is a ticket and the line text is the ticket subject. Quick things are done in the list; anything bigger opens
the normal ticket edit.

- Typing a line at the bottom and pressing Enter creates a ticket.
- The checkbox closes the ticket and crosses the line out.
- Dragging a line onto another one makes it a child, like bullets in Apple Notes. Dragging between lines reorders.
- Clicking the text edits the subject in place.
- Hovering a line shows Redmine's own ticket tooltip.
- Right-clicking a line opens a small menu: set priority, assign to, set due date, open full edit, delete.
- Full edit opens in a modal, with all fields and file uploads.

## Acceptance behaviours

1. When a person with permission opens a project's To-do page, then every open ticket of that project is listed, children
   nested under their parent, in the stored order; closed tickets are hidden until the toggle is on.
2. When the toggle shows closed tickets, then they appear crossed out in their place.
3. When a person without the permission, or in a project without the module, asks for the page, then access is refused
   like any other Redmine page.
4. When a new line is submitted, then a ticket is created in that project with the given subject, the default tracker,
   status and priority, assigned to the person, and it appears last in the list.
5. When a blank line is submitted, then nothing is created.
6. When a line's text is edited, then the ticket subject changes and a journal entry is written like any edit.
7. When a line is checked, then the ticket gets the first closed status its workflow allows for that person, and the line
   is crossed out.
8. When no closed status is allowed, then the ticket is unchanged, the checkbox goes back, and the person sees why.
9. When a closed line is unchecked, then the ticket returns to its tracker's default status.
10. When a line with open children is checked, then the person is asked once, with the number of tickets that will close;
    on Cancel nothing changes; on confirm the line and all its open descendants are closed.
11. When a line is dropped onto another, then it becomes that line's child; when the person lacks the right to manage
    subtasks, or the move would make a loop, then nothing changes and the person sees why.
12. When a line is dropped between two lines, then it gets that position and, if it moves out of a parent, it becomes a
    top level or sibling line as dropped.
13. When the order changes, then everyone who opens the page afterwards sees the same order. Lines never placed (tickets
    created elsewhere) appear after the placed ones, by ticket id.
14. When the right-click menu sets priority, assignee or due date, then only that field changes, as a normal ticket edit.
15. When Delete is chosen, then the person confirms once, and the ticket is deleted only if Redmine would allow it.
16. When a change is made from the list, then it goes through the normal ticket save, so validation, workflow,
    permissions, journals and notification mails behave exactly as for any edit.
17. When the plugin is installed on a stock Redmine 7, then it needs no other gem, no JavaScript library, no settings
    page and no configuration besides enabling the module for a project and granting the permission.

## Decisions

- **One list per project**, not per person. The project is the unit Redmine already uses for permissions.
- **Order is shared per project** and stored in one small plugin table (ticket and position). Redmine has no manual
  order for tickets. This is the only schema change. Per-person order was rejected as more code for little gain.
- **Everything goes through Redmine's ticket model**, never around it, so workflow, permissions, journals and mail stay
  Redmine's. The reason: the less the plugin re-implements, the less breaks on upgrade.
- **Closing picks the first closed status the workflow allows.** A fixed status in settings was rejected because
  workflows can forbid it, and it would need a settings page.
- **Parent with open children:** confirm once, naming the count, then close the whole subtree. A silent mass close was
  rejected, and a second confirmation was rejected as friction on a legitimate action.
- **Notifications are not suppressed.** People who rely on mail must still see changes.
- **Front end:** server-rendered pages and Stimulus (already in Redmine 7) with native browser drag and drop. No Turbo
  (Redmine 7 does not ship it), no new JavaScript, no new gems. Reason: easiest to maintain and works on a stock install.
- **Hover card is Redmine's own ticket tooltip**, nothing extra.
- **Right-click menu uses Redmine's context menu hooks**; the full edit modal uses Redmine's own modal. Whether the
  ticket edit form can be loaded into the modal as it is, or needs a small wrapper, is checked in the first slice.
- **Access:** a project module named To-do and one permission to use the list. Each change is still checked against the
  person's ordinary rights on the ticket.
- **License:** GPL v2 or later, matching Redmine. MIT was considered; a plugin runs inside Redmine's process, so matching
  is the safe choice. The headers are checked against Redmine's source before the license file is written.

## Test seams

One seam: the plugin's HTTP interface, tested with Redmine's integration tests (a signed in request, then the response and
the database). It covers acceptance behaviours 1 to 16, because every behaviour is a request that changes tickets or the
stored order, and it keeps tests independent of how the controllers and views are organised.

What a good test looks like here: sign in as a user with a role, send the request the browser would send, assert the
ticket (subject, status, parent, journal count, mail count) and the stored order. The expected values are literals, not
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

- Redmine 7.0.2 facts relied on (read from its source, not run): Stimulus on importmap, no Turbo, jQuery and jQuery UI
  present, no sortable library, context menu hooks exist, the tooltip is plain CSS, the modal helper exists, and a status
  the workflow forbids is silently ignored by the ticket update, so the plugin must check the result.
- Closing a parent through the ticket model may be refused by Redmine while children are open; the subtree close must
  close children first. To be confirmed in the first slice.
