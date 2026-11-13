---
type: Convention
title: Testing conventions
description: Minitest against the dummy app with self-contained, order-independent tests — no setup/teardown, explicit helpers, ensure-restored global state.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/test/test_helper.rb
tags: [testing]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude-md
    title: CLAUDE.md — Testing conventions
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/CLAUDE.md
---

# Rules

- **No `setup`/`teardown`.** Each test creates its own data inline and restores any global state
  it touches.[^claude-md]
- Helpers from `test/test_helper.rb`, called explicitly: `acting_admin` / `acting_member` (create
  the acting user **first** — the dummy resolves `current_user` as `User.first`) and
  `with_config(**opts) { … }` to override configuration temporarily.
- Other global mutation (e.g. redefining a policy method) is restored in `ensure`.
- Generator tests call `prepare_destination` at the start of each test.
- Tests must be order-independent; check with several seeds:
  `bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require File.expand_path(f) }' -- --seed N`

# Why

Global state here is real — `RubyUIAdmin.configuration`, the resource registry, policy classes —
so hidden fixtures leak between tests and only fail under some seeds.

# Running

`bundle exec rake test`, against `test/dummy` (part of the test setup; never delete it). Prepare
its DB with `cd test/dummy && bin/rails db:prepare`. Database pitfalls are in
[dev-reload gotchas](/development/dev-reload-gotchas.md).
