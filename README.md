# redmine-todo

TL;DR: a Redmine plugin that shows tickets as a plain to-do list. Redmine 7 and up only.

Most of the time I just need a flat list (do A, do B, a nested item under B). If an item deserves more, it
becomes a full ticket; if not, it stays a line in a list.

## Status

Nothing is built yet. The plan is in [docs/roadmap/ROADMAP.md](docs/roadmap/ROADMAP.md). The license is still to be chosen.

## Try it

A throwaway Redmine 7 runs from this folder, with the repository mounted as the plugin:

    docker compose up -d
    open http://localhost:3007

Wipe it with `docker compose down -v`.
