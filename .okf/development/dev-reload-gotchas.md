---
type: Playbook
title: Development gotchas
description: Things that silently go wrong while developing the gem — lib/ changes need a restart, stale reloaded classes, schema.rb vs migrations, and polluting the test DB.
tags: [testing, zeitwerk, boot]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude-md
    title: CLAUDE.md — Dummy app & assets gotchas
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/CLAUDE.md
---

# Gotchas

| Symptom | Cause | Fix |
|---|---|---|
| A change in `lib/` has no effect | `lib/` is `require`d once, not reloaded ([engine boot](/architecture/engine-boot.md)) | restart the server; `app/` and `public/` JS do reload |
| Duplicate sidebar entries in dev | `BaseResource`/`BaseDashboard.descendants` keeps stale classes across reloads | the managers dedupe by name — keep that when touching discovery ([resource registry](/architecture/resource-registry.md)) |
| New dummy column missing in tests | the test DB loads `test/dummy/db/schema.rb`, not migrations | after adding a migration, also edit `schema.rb` (column + bump `version:`) |
| Confusing cross-test failures | an ad-hoc `Model.create!` against `RAILS_ENV=test` outside a transaction committed to the sqlite DB | clean up with `delete_all`; never debug-write to the test DB that way |

All from the project's working notes.[^claude-md] See also [testing conventions](/development/testing-conventions.md).
