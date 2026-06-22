# Authorization with action_policy

`ruby_ui_admin` authorizes every request through [action_policy](https://actionpolicy.evilmartians.io)
by default, using a small set of conventional rule names per resource.

> action_policy is the **default adapter**. The backend is pluggable — Pundit, CanCanCan and custom
> adapters are also supported via `config.authorization_client`. See
> [Authorization adapters](adapters.md).

## Policies

Admin policies live in `app/ruby_ui_admin/policies` (`RubyUIAdmin::Policies::*`) and inherit
`RubyUIAdmin::BasePolicy`:

```ruby
module RubyUIAdmin
  module Policies
    class PostPolicy < RubyUIAdmin::BasePolicy
      def index? = true
      def show?  = true
      def create? = true
      def update? = true
      def destroy? = user.admin?

      relation_scope do |relation|
        next relation if user.admin?
        relation.where(published: true)
      end
    end
  end
end
```

Attach a policy to a resource with `self.authorization_policy = RubyUIAdmin::Policies::PostPolicy`.

## Rule mapping

| Controller action | Rule | Target |
|---|---|---|
| index | `index?` | model class |
| show | `show?` | record |
| new / create | `create?` | record |
| edit / update | `update?` | record |
| destroy | `destroy?` | record |

Custom actions are authorized with `act_on?`. Individual fields can be hidden per user with
`view_<field>?` (and per-view `index_/show_/edit_<field>?`) — see
[Field-level authorization](field-authorization.md). Association attach/detach rules are
added in a later phase.

## Scopes

The index query is filtered through the policy's `relation_scope`, so each user only sees
the records they're allowed to. If a policy defines no scope, the relation is returned
unchanged.

## `explicit_authorization`

- `false` (default): a rule the policy doesn't define is **allowed** (falls back to the
  `manage?` default rule on `BasePolicy`).
- `true`: undefined rules and missing policies are **denied** — a strict, deny-by-default mode.

```ruby
RubyUIAdmin.configure { |c| c.explicit_authorization = true }
```

## Context

`BasePolicy` declares `authorize :user` (from `config.current_user_method`) and
`authorize :true_user` (from `config.true_user_method`, falling back to the current user) —
so rules can gate on the real user behind an impersonation. Any other context (e.g. a tenant)
can be layered in via a custom base policy.
