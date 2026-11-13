---
type: Component
title: Resource registry and dynamic routes
description: ResourceManager discovers host resources, and the engine draws one RESTful route set per resource from it at route-draw time.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/resource_manager.rb
tags: [routing, zeitwerk, boot]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: manager
    title: lib/ruby_ui_admin/resource_manager.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/resource_manager.rb
  - id: routes
    title: config/routes.rb and config/routes/dynamic_routes.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/config/routes.rb
  - id: entry
    title: RubyUIAdmin.controller_for
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin.rb
---

# Overview

`RubyUIAdmin.resource_manager` lists every [resource](/dsl/resource-dsl.md) class. Discovery:[^manager]

1. If `config.resources` is set, constantize exactly those names.
2. Otherwise eager-load `app/ruby_ui_admin/resources` (Zeitwerk `eager_load_dir`, with a namespace
   fallback for old Zeitwerk).
3. Take `BaseResource.descendants`, keep only named classes under `RubyUIAdmin::Resources::`
   (anonymous test subclasses are excluded), **dedupe by name and re-constantize** — in dev,
   `descendants` retains stale classes from earlier reloads.

Lookups: `find_by_route_key` (falls back to the singular resource name) and `find_for_model`,
which honours `config.model_resource_mapping` first.

# Dynamic routes

`config/routes/dynamic_routes.rb` iterates the registry and draws
`resources <route_key>, as: "resources_<route_key>", defaults: {resource_name: …}`.[^routes] Path
helpers are therefore `resources_posts_path`, `resources_post_path(record)`, etc.

- `route_key` derives from the **resource** name, not the model, so two resources backed by the
  same model get distinct routes.
- The controller is `RubyUIAdmin.controller_for(resource)`: a per-resource controller when the
  host has `app/controllers/ruby_ui_admin/<route_key>_controller.rb`, else the generic
  `resources` controller — detected by **file existence**.[^entry]
- Action routes (`/:resource_name/actions/:action_id`) are drawn *before* the dynamic routes so the
  three-segment path wins.[^routes]

Because routes are drawn from the registry, adding a resource in development needs a route
reload (the `to_prepare` reboot handles it); see [engine boot](/architecture/engine-boot.md).
