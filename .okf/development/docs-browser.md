---
type: Component
title: In-app docs browser
description: DocsController renders the gem's docs/*.md as HTML at <mount>/docs, gated by config.docs_enabled, with its own self-contained page instead of the admin layout.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/docs_controller.rb
tags: [security, assets]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: controller
    title: app/controllers/ruby_ui_admin/docs_controller.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/docs_controller.rb
  - id: config
    title: Configuration#docs_enabled?
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/configuration.rb
---

# Overview

`config.docs_enabled` accepts `:local` (default — dev/test only, open), `true` (all envs; outside
local envs it runs behind `authenticate_admin!`), `false`, or a callable.[^config] The routes are
drawn at boot from `docs_enabled?`, so changing the setting needs a restart.

# Design choices

- **Own page, not the admin layout.** `Views::Docs` embeds its own CSS so the docs work in a host
  whose RubyUI/Tailwind wiring is still half-done — exactly when someone needs the docs.
- **Path-traversal guarded**: only existing `.md` files under `Engine.root/docs`, null bytes
  rejected.[^controller]
- **kramdown GFM, no Rouge**: Rouge's kramdown formatter is deprecated and warns once per code
  block, flooding the log. kramdown is required lazily; if missing, the page shows install help.
  Hosts add `kramdown` + `kramdown-parser-gfm` to the right Gemfile group.[^controller]
- Relative `*.md` links are rewritten to the docs route.

Like every admin request it goes through the [request context](/architecture/request-context.md)
(`authenticate_admin!` is skipped only in local envs).

Docs are part of the packaged gem (`docs/**`, minus `docs/assets/` media).
