# Authorization adapters

Authorization is **pluggable**. The admin checks every request through an *adapter*, selected with
`config.authorization_client`:

```ruby
RubyUIAdmin.configure do |config|
  config.authorization_client = :action_policy   # default
  # config.authorization_client = :pundit
  # config.authorization_client = :cancancan
  # config.authorization_client = MyApp::CustomAdapter
  # config.authorization_client = nil            # disable authorization entirely
end
```

Internally `RubyUIAdmin::Services::AuthorizationService` is a thin facade that resolves the adapter
(`RubyUIAdmin::Authorization.adapter_class`) and delegates to it, so controllers, views and
resources stay backend-agnostic.

## Built-in adapters

| Value | Backend | Requires gem | Policy resolution |
|---|---|---|---|
| `:action_policy` (default) | [action_policy](https://actionpolicy.evilmartians.io) | — (gem dependency) | per-resource `authorization_policy` (`RubyUIAdmin::BasePolicy` subclass) |
| `:pundit` | [Pundit](https://github.com/varvet/pundit) | `pundit` | per-resource `authorization_policy`, else Pundit inference |
| `:cancancan` | [CanCanCan](https://github.com/CanCanCommunity/cancancan) | `cancancan` | a single global `Ability` (`config.cancancan_ability_class`) |

`:pundit`/`:cancancan` are loaded **lazily** — the gem only requires them when selected, so they're
optional dependencies you add to your own `Gemfile`.

## Capability matrix

| Capability | action_policy | Pundit | CanCanCan |
|---|---|---|---|
| CRUD (`index`/`show`/`new`/`edit`/`create`/`update`/`destroy`) | ✅ | ✅ | ✅ |
| Record scope on the index | ✅ `relation_scope` | ✅ policy `Scope` | ✅ `accessible_by` |
| Field-level rules (`view_<field>?`, …) | ✅ | ✅ (if the policy defines them) | ❌ not supported (all fields visible) |
| Custom action auth (`act_on?`) | ✅ | ✅ (if defined) | ⚠️ via the mapped action / `:manage` |
| `true_user` (impersonation context) | ✅ | ❌ (policies get `user` only) | ❌ (Ability gets `user` only) |
| `explicit_authorization` fallback (undefined rule → allowed/denied) | ✅ | ✅ | ❌ (CanCanCan denies whatever the Ability doesn't grant) |

> **Recommendation:** use `:action_policy` (or `:pundit`) if you need field-level rules,
> impersonation context, or the `explicit_authorization` fallback. `:cancancan` covers CRUD +
> record scoping; field-level authorization is silently skipped (every field stays visible).

## Using Pundit

Add `gem "pundit"`, set `config.authorization_client = :pundit`, and point each resource's
`authorization_policy` at a Pundit policy (one that responds to `index?`/`show?`/… and, optionally,
a `Scope`). Rules the policy doesn't define fall back to `explicit_authorization`. Pundit policies
receive only `user` — `true_user` is not passed.

## Using CanCanCan

Add `gem "cancancan"`, set `config.authorization_client = :cancancan`, and define a single
`Ability` (override the class with `config.cancancan_ability_class` if it isn't named `Ability`):

```ruby
class Ability
  include CanCan::Ability
  def initialize(user)
    can :manage, :all if user&.admin?
    can :read, Post, published: true
  end
end
```

The index scope follows the Ability's rules (`accessible_by`). Note the limitations in the matrix:
no field-level rules, and `explicit_authorization` has no effect (grant access in the Ability).

## Writing a custom adapter

Subclass `RubyUIAdmin::Authorization::Adapter` and implement the four backend methods. The base
provides the context (`user`, `true_user`, `record`, `policy_class`), `allowed?`, `normalize_rule`
and `handle_missing_policy`:

```ruby
module MyApp
  class CustomAdapter < RubyUIAdmin::Authorization::Adapter
    # Authorize a rule (`:show`, `:update`, `:act_on`, `:view_<field>`…). Return a boolean; raise
    # RubyUIAdmin::NotAuthorizedError when denied and raise_exception is true.
    def authorize_action(rule, record: nil, raise_exception: true)
      # ... your logic, using `user` / `true_user` / `policy_class` ...
    end

    # Apply a record scope to the index relation (return it unchanged when there's no scope).
    def apply_policy(scope) = scope

    # Does the resolved policy respond to this rule (for the given record)?
    def has_rule?(rule, record: nil) = false

    # Does the policy CLASS explicitly define this rule? (field-level: undefined ⇒ visible)
    def defines_rule?(rule) = false
  end
end

RubyUIAdmin.configure { |c| c.authorization_client = MyApp::CustomAdapter }
```

A custom adapter class is used as-is. To expose it under a symbol instead, add it to
`RubyUIAdmin::Authorization::REGISTRY`.
