---
type: Component
title: Resource DSL
description: BaseResource — the declarative class a host writes per admin resource, and how its field tree is rebuilt and filtered per view.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_resource.rb
tags: [dsl-core, avo-parity, querying]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: base-resource
    title: lib/ruby_ui_admin/base_resource.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_resource.rb
  - id: structure
    title: lib/ruby_ui_admin/structure.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/structure.rb
  - id: docs
    title: docs/resources/overview.md
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/docs/resources/overview.md
---

# Overview

A host resource (`RubyUIAdmin::Resources::Post < RubyUIAdmin::BaseResource`) has two layers:[^base-resource]

- **Class attributes** (`self.title`, `self.includes`, `self.index_query`, `self.authorization_policy`,
  `self.countless`, `self.row_controls`, `self.visible_on_sidebar`, …) — static configuration.
- **Instance DSL methods** the host overrides: `def fields`, `def actions`, `def filters`,
  `def scopes`. They are *re-run on every call* (`get_fields`, `get_actions`, …), not cached at
  class load.

The DSL shape (and the `panel name:` keyword form) is deliberately Avo-compatible, to ease
migrating Avo resources.[^base-resource][^docs]

# The re-evaluation model

Because `fields` runs per request on a **hydrated** instance (`hydrate(record:, view:, user:, params:)`),
field declarations can branch on `record`, `view` and `current_user`. `build_items` resets a
collector stack and runs `fields`; `panel`/`tabs`/`tab` push containers
([Structure](/dsl/fields.md)) so nesting is captured as a tree.[^structure]

- `field_structure(view:)` returns the tree filtered for that view (used by show/form). Empty
  panels/tabs are dropped, and **bare fields or panels placed directly in `tabs do`** become
  implicit tabs named after the field/panel.
- `get_fields(view:)` returns the flat leaf list (index columns, strong params, record filling),
  filtered by `only_on`/`hide_on`, `visible:` and [field-level authorization](/authorization/field-level-authorization.md).

# Model and naming

- `model_class` derives from the demodulized resource name, overridable with `self.model_class =`.
- `route_key` comes from the resource name — see [resource registry](/architecture/resource-registry.md).
- `discover_columns` / `discover_associations` auto-declare fields from the schema; foreign-key
  `*_id` columns are skipped unless named in `only:` (use associations instead).

# Querying

`base_query` = `model.all` → `includes` → `index_query` proc (readers `query`, `params`). The
index then applies, in order: policy scope → [scope](/dsl/filters-and-scopes.md) → filters →
sorting → pagy (countless when `self.countless` or global `pagination: {type: :countless}`).
