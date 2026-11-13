---
type: Decision
title: Explicit authorization fallback (manage?)
description: What happens when a policy or rule is missing — allowed by default, denied when config.explicit_authorization is true, identically across action_policy and Pundit.
tags: [authorization, security]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: base-policy
    title: lib/ruby_ui_admin/base_policy.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_policy.rb
  - id: adapter
    title: Adapter#handle_missing_policy
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/authorization/adapter.rb
---

# Decision

One switch, `config.explicit_authorization` (default `false`), decides every "no opinion" case:[^adapter]

- `false` — permissive: a missing policy or an undefined rule is **allowed**. Good for getting
  started.
- `true` — locked down: anything not explicitly granted is **denied**.

# How it is implemented

- `RubyUIAdmin::BasePolicy < ActionPolicy::Base` defines `manage?` (action_policy's default rule)
  as `!explicit_authorization`. It also **redefines `index?` and `create?` to `manage?`**, because
  action_policy's `Defaults` hard-code those two to `false` — without this, a policy that defines
  nothing would block the index and creation even in permissive mode.[^base-policy]
- `authorize :user, allow_nil: true` (and `true_user`) so policies evaluate with no signed-in user.
- `BasePolicy` intentionally declares no `relation_scope`: the Rails alias registers only after
  the action_policy railtie loads, but this class is required at gem load. The adapter rescues the
  unknown-scope errors instead.[^base-policy]
- Adapters share `handle_missing_policy` so missing-policy semantics are identical across
  backends (CanCanCan excepted — see [adapter architecture](/authorization/adapter-architecture.md)).

Field rules deliberately do **not** follow this switch — see
[field-level authorization](/authorization/field-level-authorization.md).
