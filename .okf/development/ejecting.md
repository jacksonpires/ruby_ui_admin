---
type: Component
title: Ejecting and per-resource controllers
description: Two override mechanisms that rely on Rails path precedence instead of configuration — ejected engine files shadow the gem's, and a per-resource controller replaces the generic one.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/generators/ruby_ui_admin/eject/eject_generator.rb
tags: [customization, extensibility]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: eject-docs
    title: docs/customization/ejecting.md
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/docs/customization/ejecting.md
  - id: controller
    title: ResourcesController lifecycle hooks
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/resources_controller.rb
---

# Ejecting

`rails g ruby_ui_admin:eject --view|--controller|--ui <name>` copies an engine file verbatim to the
same path in the host. Host autoload paths take precedence over the engine's, so the copy defines
the same constant and wins — no monkey-patching.[^eject-docs] Every ejected file is a fork the
host now maintains, so prefer configuration first.

# Per-resource controllers

`rails g ruby_ui_admin:controller Post` creates `app/controllers/ruby_ui_admin/posts_controller.rb`;
its mere existence routes that resource to it (see
[resource registry](/architecture/resource-registry.md)). It overrides the lifecycle hooks
of `ResourcesController`: `create/update/destroy_success_action`, `*_fail_action`,
`after_*_path` and `*_success_message`.[^controller]

# Other generators

`install`, `components`, `assets`, `resource`, `action`, `filter`, `policy`, `scope`,
`dashboard`, `card`, `locales`; rake: `all_resources`, `tailwind_source`, `build_assets`,
`version`.
