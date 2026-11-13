---
type: Decision
title: Field-level authorization
description: Per-field visibility rules (show_<id>?, edit_<id>?, view_<id>?…) checked most-specific first, where an undefined rule means "no opinion" and the field stays visible even under explicit authorization.
tags: [authorization, security, dsl-core]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: base-resource
    title: BaseResource#field_authorized? / #candidate_field_rules
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_resource.rb
  - id: controller
    title: ResourcesController#fill_record
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/resources_controller.rb
---

# Rule lookup

For a field `id` the resource tries, most specific first:[^base-resource]

| View | Candidate rules |
|---|---|
| index | `index_<id>?`, `view_<id>?` |
| show | `show_<id>?`, `view_<id>?` |
| new | `new_<id>?`, `edit_<id>?`, `view_<id>?` |
| edit | `edit_<id>?`, `view_<id>?` |

The first rule the policy **class explicitly defines** (`defines_rule?` — a real public method, not
satisfied by the `manage?` default) decides.

# Decision: undefined means visible

If no candidate is defined, the field is visible — *even with `explicit_authorization = true`*.
Otherwise turning on explicit mode would silently hide every unconfigured field on every
resource.[^base-resource] Contrast with record rules in
[explicit authorization](/authorization/explicit-authorization.md).

# It also guards writes

`fill_record` hydrates the resource with the record and only permits/fills fields returned by
`get_fields(view:)`, which already excludes unauthorized ones — a hidden field cannot be written
by crafting params.[^controller]

Not supported by the CanCanCan adapter (see [adapter architecture](/authorization/adapter-architecture.md)).
