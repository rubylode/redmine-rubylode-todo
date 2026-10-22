# Design review brief

A prompt to give a design reviewer, together with screenshots of the To-do page (attach them, see the last section).

## Prompt

You are reviewing the design of a Redmine 7 plugin called redmine-todo. It adds a To-do page to a project. Every line
on the page is a real Redmine ticket, shown as a plain checklist with nested lines, in the style of a notes app. I want
concrete suggestions to make it clearer, calmer and faster to use. Please do not suggest a rewrite on another stack.

What the page does today:

- Lines are nested to any depth. Each line has a fold arrow (only when it has children), a checkbox, the ticket subject,
  the ticket number as a small link, and, on parents, a small count such as "18 open, 0 closed".
- Ticking a checkbox closes the ticket and crosses the line out. The line stays in place until the page is reloaded.
- Clicking the subject edits it in place. Enter saves and opens a new line below. Tab and Shift+Tab nest and un-nest a
  new line. Up, Down and Alt+arrows move between and rearrange lines. A plus button on a line (shown on hover) adds a
  child. Pasting several lines creates one ticket per line.
- Lines are dragged onto the middle of another to nest, or to its top or bottom edge to reorder.
- Hovering a line shows Redmine's own ticket tooltip, placed beside the pointer. Right click opens Redmine's own
  context menu.
- Above the list: Collapse all, Expand all and Show closed tickets. Below it: one input to add a line at the end.

Constraints you must respect:

- Redmine's own look and its themes (including dark ones) must keep working. Use plain CSS and Redmine's colours and
  spacing, with no CSS framework and no icon font beyond what Redmine ships.
- No JavaScript framework. Small changes to a Stimulus controller and to the HTML are fine.
- It must work with a mouse, with the keyboard alone, and on a phone-width screen.
- Subjects can be very long (a few hundred characters, often a whole paragraph) and lists can have hundreds of lines.

Known problems I would like your view on:

- Very long subjects make the list hard to scan. Should they wrap, truncate to a line or two with a way to expand, or
  something else?
- The fold arrow, checkbox, subject and counts compete for attention. What is the right visual hierarchy and density?
- Nothing on the page says that keyboard editing, nesting and pasting exist. How do I make them discoverable without
  clutter?
- The drop targets for drag and drop (before, after, as a child) are easy to get wrong. How should they look?
- Closed lines, folded lines, lines being edited and the inline new line each need a clear state.

Please answer with:

1. The five changes that would improve the page most, in order, each with the reason.
2. For each, specific CSS or markup guidance I can apply (spacing, sizes, colours as Redmine variables, states).
3. A short description or mock-up of these states: a long subject, a parent with counts, hover, editing, the inline
   new line, drag over, a closed line and an empty list.
4. Anything in the accessibility of the page (focus order, labels, contrast, touch targets) that should change.

## Attachments to include

Full-page screenshots of: a long list with nested lines, a line being edited, the inline new line, a line with the
tooltip open, a drag in progress, and the page at phone width. Use a project with realistic content.
