---
type: Decision
title: Host-owned assets (Option 3)
description: The admin renders the host's RubyUI components, so the host owns the CSS (its Tailwind build) and JS (its bundler/importmap) and wires them into the admin layout via config.head_assets.
tags: [assets, rubyui, hotwire]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude-md
    title: CLAUDE.md — Dummy app & assets gotchas
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/CLAUDE.md
  - id: js-docs
    title: docs/customization/javascript.md
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/docs/customization/javascript.md
  - id: tailwind-source
    title: lib/ruby_ui_admin/tailwind_source.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/tailwind_source.rb
  - id: config
    title: Configuration#head_assets
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/configuration.rb
---

# Decision

Internally called **Option 3**: the engine renders the **host's** `RubyUI::*` components instead
of shipping its own copies, so the host's Tailwind build and JS bundle are the source of
truth.[^claude-md] The host passes a proc in `config.head_assets`; the layout evaluates it in the
Rails view context (`stylesheet_link_tag`, `javascript_importmap_tags`…). When nil, the layout
renders no assets.[^config]

# Why

The admin looks like the host app (shared theme tokens and component edits) and there is one
Tailwind and one Stimulus runtime per page instead of two competing ones.

# Consequences

- **CSS**: the host's Tailwind must see the admin's classes. `rake ruby_ui_admin:tailwind_source`
  extracts every class candidate from the engine views into a file inside the host tree, because
  `@source "<gem path>/**/*.rb"` breaks when the gem path differs between dev/CI/deploy. Re-run it
  after upgrading the gem.[^tailwind-source]
- **JS**: the host registers the `rua--*` controllers plus `ruby-ui--toaster`/`ruby-ui--toast`
  (flash uses Toast even if the host doesn't — otherwise toasts silently never show).
  `rails g ruby_ui_admin:assets` copies them for bundler hosts; importmap hosts pin the
  engine-served undigested `index.js` instead, because Propshaft digests copied files and breaks
  their relative imports.[^js-docs]
- The engine still ships a precompiled `public/ruby-ui-admin-assets/application.css`
  (`rake ruby_ui_admin:build_assets`); the dummy app reuses it for tests, but it is **not** the
  source of truth for a real host.[^claude-md]
- In a Turbo + importmap host, links into the engine need `data-turbo="false"` (a full load) or
  the engine's importmap won't apply.

Related: [component ownership](/frontend/component-ownership.md), [Hotwire only](/frontend/hotwire-only.md).
