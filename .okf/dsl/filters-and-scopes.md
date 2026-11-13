---
type: Component
title: Filters and scopes
description: Index narrowing — scopes are mutually exclusive tabs, filters are combinable query-string params; both keyed by their class path.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/filters/base_filter.rb
tags: [querying, dsl-core]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: filter
    title: lib/ruby_ui_admin/filters/base_filter.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/filters/base_filter.rb
  - id: scope
    title: lib/ruby_ui_admin/scopes/base_scope.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/scopes/base_scope.rb
  - id: controller
    title: ResourcesController#apply_scope / #apply_filters
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/resources_controller.rb
---

# Scopes

A scope is one tab above the index; exactly one applies at a time.[^scope]

- `self.scope` is a **Symbol** (calls the model's named scope) or a zero-arity lambda with
  `query`/`params`.
- Selection: explicit `?scope=key` wins; `scope=all` clears it; otherwise the default scope.[^controller]
- `scope Klass, default: true` on the resource **overrides** the scope class's own `self.default`.
- Hide the "All" tab with `remove_scope_all` (callable inside `def scopes`) or the class
  attribute.

Not to be confused with *authorization* scopes (policy `relation_scope`), which always apply
first — see [adapter architecture](/authorization/adapter-architecture.md).

# Filters

Filters combine; each reads `params[:filters][param_key]` and implements
`apply(request, query, value)`.[^filter] Types (text, select, multiple_select, boolean) are
inherited down the class chain via `register_type`.

A filter's `default` applies **only when its key was not submitted at all**, so a filter the
user explicitly cleared stays cleared.[^controller]

# Shared conventions

Both use the class-path key convention (`RubyUIAdmin::Filters::Published` → `published`) and the
`self.name =` override that still falls back to the real class name so Zeitwerk keeps working —
the same pattern as actions and dashboards.
