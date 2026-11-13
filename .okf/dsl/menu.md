---
type: Component
title: Sidebar menu
description: config.main_menu is a block instance_exec'd against Menu::Builder, producing a tree of section/resource/link/dashboard items.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/menu/builder.rb
tags: [routing]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: builder
    title: lib/ruby_ui_admin/menu/builder.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/menu/builder.rb
---

# Overview

Without `config.main_menu`, the sidebar lists every resource with `visible_on_sidebar`. With it,
the block is evaluated by `Menu::Builder` (`section`/`group`, `resource`/`resources`, `link`,
`dashboard`).[^builder]

`resource :name` looks the resource up by route key and **silently skips it when not found** —
a typo produces a missing entry, not an error. Resolution goes through the
[resource registry](/architecture/resource-registry.md).

The sign-out item is separate: `config.sign_out_path_name` names a host route helper resolved via
`main_app`, with `sign_out_method` (default `:delete`, Devise-style).
