---
type: Decision
title: Adapter-based authorization
description: Authorization goes through a backend-agnostic facade (AuthorizationService) that delegates to an adapter chosen by config.authorization_client — action_policy by default, Pundit, CanCanCan, a custom class, or nil.
tags: [authorization, extensibility]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: registry
    title: lib/ruby_ui_admin/authorization.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/authorization.rb
  - id: adapter
    title: lib/ruby_ui_admin/authorization/adapter.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/authorization/adapter.rb
  - id: service
    title: lib/ruby_ui_admin/services/authorization_service.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/services/authorization_service.rb
  - id: cancan
    title: lib/ruby_ui_admin/authorization/can_can_can_adapter.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/authorization/can_can_can_adapter.rb
  - id: pundit
    title: lib/ruby_ui_admin/authorization/pundit_adapter.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/authorization/pundit_adapter.rb
  - id: docs
    title: docs/authorization/adapters.md
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/docs/authorization/adapters.md
---

# Decision

Controllers, views and resources never talk to a policy library directly. They call
`Services::AuthorizationService`, a facade that resolves an adapter via
`RubyUIAdmin::Authorization.adapter_class` and delegates.[^service] This keeps call sites stable
while hosts pick the library they already use.[^docs]

# Why

The gem started action_policy-only (still a hard runtime dependency and the default). Hosts using
Pundit or CanCanCan should not need a second authorization system just for the admin.

# How it is resolved

`config.authorization_client` may be:[^registry]

| Value | Adapter |
|---|---|
| `:action_policy` (default) | `ActionPolicyAdapter` |
| `:pundit` | `PunditAdapter` — `require`d lazily; raises a helpful `LoadError` when the gem is missing |
| `:cancancan` | `CanCanCanAdapter` — lazy, same |
| a `Class` | a custom `Authorization::Adapter` subclass |
| `nil` | authorization disabled: every check short-circuits to allowed |

Pundit/CanCanCan are referenced inside lambdas in `REGISTRY`, so they are never loaded unless
selected — they are **not** gem dependencies.

# The adapter contract

Subclasses implement `authorize_action`, `apply_policy`, `has_rule?`, `defines_rule?`; the base
class holds the context (`user`, `true_user`, `record`, `policy_class`), `allowed?`,
`normalize_rule` (adds the `?`) and `handle_missing_policy`.[^adapter] The rule vocabulary is
`index? show? create? update? destroy? act_on?` plus field rules — see
[field-level authorization](/authorization/field-level-authorization.md).

# Backend differences (by design)

- **action_policy / Pundit**: undefined rule or missing policy → the
  [explicit-authorization fallback](/authorization/explicit-authorization.md). Pundit infers the
  policy when the resource sets none, and receives only `user` (no `true_user`).[^pundit]
- **CanCanCan is partial**: one global Ability (`config.cancancan_ability_class`, default
  `Ability`), per-resource `authorization_policy` ignored, **no field-level rules**
  (`defines_rule?` is always false), `explicit_authorization` has no effect, no `true_user`, and an
  index with no matching `can` rule is an empty relation.[^cancan]

Record scopes (`apply_policy`) run before scopes/filters on the index; an adapter that finds no
scope returns the relation unchanged.
