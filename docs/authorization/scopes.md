# Authorization scopes

A policy's **scope** filters the index query so each user only sees the records they're
allowed to — action_policy's equivalent of Pundit's `policy_scope`. Define it with
`relation_scope` in the resource policy.

```ruby
module RubyUIAdmin
  module Policies
    class PostPolicy < RubyUIAdmin::BasePolicy
      relation_scope do |relation|
        next relation if user.admin?

        relation.where(user_id: user.id)   # members see only their own
      end
    end
  end
end
```

## How it's applied

On the index, the query flows through:

```
model.all → policy relation_scope → named scope → filters → sorting → pagination
```

So the authorization scope runs first and can't be bypassed by filters or named scopes.

- If the policy defines **no** `relation_scope`, the relation is returned unchanged (all
  records, subject to the other steps).
- If `config.authorization_client` is `nil`, scoping is skipped entirely.

## Not the same as named scopes

This is **record-level authorization**, distinct from [named index scopes](../resources/scopes.md)
(the tab bar). Both narrow the index query, but:

- **Authorization scope** (`relation_scope`) is enforced for security and always applied.
- **Named scopes** are user-facing tabs the user chooses between; they compose *after* the
  authorization scope.

## Using a scope elsewhere

Because the index uses the policy scope, a user who isn't allowed to see a record also can't
reach it through the index. Direct access (show/edit) is still guarded by the per-record
rules (`show?`, `update?`, …).
