---
type: Component
title: Fields
description: The field registry and BaseField contract — pure metadata objects resolved by `as:` symbol, rendered by separate Phlex views.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/fields/base_field.rb
tags: [dsl-core, rendering]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: base-field
    title: lib/ruby_ui_admin/fields/base_field.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/fields/base_field.rb
  - id: manager
    title: lib/ruby_ui_admin/fields/field_manager.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/fields/field_manager.rb
  - id: catalog
    title: docs/fields/overview.md
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/docs/fields/overview.md
---

# Overview

Each field class calls `register_as :text` (etc.) to enter the `Fields.mapping` registry;
`field :title, as: :text` resolves through `Fields.field_class_for`, which raises listing the
registered keys on a typo.[^manager] The field catalog (text, number, belongs_to, has_many,
files, key_value, status, …) is documented in the gem docs.[^catalog]

Fields are **data, not views**: rendering lives in `Views::FieldValue` (display) and
`Views::FieldInput` (forms), which switch on `field.type`.[^base-field] That split is why a new
field type needs both a `lib/` class and a branch in those views, and why hosts customise
rendering by [ejecting](/development/ejecting.md) those two views.

# Contract points worth knowing

| Concern | Hook | Note |
|---|---|---|
| Value | `value(record, view_context:)` | a field block makes it **computed**, evaluated via [ExecutionContext](/architecture/execution-context.md) |
| Display | `formatted_value` | applies `format_using:` |
| Column name | `database_id` | belongs_to appends `_id`; used for sorting |
| Strong params | `permit_params` | arrays/hashes for files, boolean_group; file fields add a "remove" input |
| Assignment | `fill(record, attributes)` | only for permitted, non-readonly, authorized fields |
| Label | `name` | `human_attribute_name` → i18n `activerecord.attributes.*` |

Forms submit under `params[:record]`; `ResourcesController` mirrors them under the model's
param key so host controllers reading `params[:post]` keep working.
