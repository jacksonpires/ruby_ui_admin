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
the test DB with `cd test/dummy && RAILS_ENV=test bin/rails db:schema:load` — **not** `db:prepare`,
which also runs `db/seeds.rb` on a fresh DB; the self-contained tests assume an empty DB and ~30 of
them fail against seeded data. Database pitfalls are in
[dev-reload gotchas](/development/dev-reload-gotchas.md).

# CI matrix

`.github/workflows/ci.yml` runs the suite on Ruby 3.2–4.0 × Rails 7.1–8.1 (Ruby 3.1 is out:
Phlex 2.x needs 3.2+). Each Rails version has `gemfiles/rails_X.Y.gemfile`, which pins `rails`
and `eval_gemfile`s the root `Gemfile` so the dev/test groups (RubyUI, auth adapters, kramdown…)
stay in one place.

Keeping the dummy app loadable on the oldest Rails in the matrix:

- `test/dummy/db/schema.rb` is pinned to `ActiveRecord::Schema[7.1]`. A schema dumped by a newer
  Rails rewrites the header (`Schema[8.1]`), which Rails 7.1–8.0 reject (`Unknown version`).
- `config.load_defaults [Rails::VERSION::STRING.to_f, 7.2].min` — 7.2 is what the suite was
  written against, and Rails 7.1 doesn't know `load_defaults 7.2`.
