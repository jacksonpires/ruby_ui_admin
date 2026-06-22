# Field-level authorization

You can hide individual fields per user by defining rules on the resource's policy. This
applies everywhere a field would appear: the index columns, the show view, **and** the
new/edit forms — including param permitting, so an unauthorized field can't be submitted.

## Rules

For a field `:views_count`, define one of these on the resource policy:

```ruby
module RubyUIAdmin
  module Policies
    class PostPolicy < RubyUIAdmin::BasePolicy
      # Generic visibility (all views):
      def view_views_count? = user.admin?

      # Or per-view (most specific wins):
      def index_views_count? = user.admin?   # index column
      def show_views_count?  = true          # show view
      def edit_views_count?  = user.admin?   # new + edit forms
    end
  end
end
```

### Resolution order

For a field `<id>` in a given view, the first **defined** rule wins:

| View | Rules checked (in order) |
|---|---|
| index | `index_<id>?` → `view_<id>?` |
| show | `show_<id>?` → `view_<id>?` |
| new | `new_<id>?` → `edit_<id>?` → `view_<id>?` |
| edit | `edit_<id>?` → `view_<id>?` |

For association fields the `<id>` is the association name (e.g. `view_comments?`).

## Default behaviour

- A field is **visible** unless a matching rule is defined **and returns false**.
- An **undefined** rule means "no opinion" — the field stays visible. This is deliberate:
  enabling [`explicit_authorization`](action-policy.md) does **not** silently hide every
  unconfigured field (only resource/action authorization is affected by that flag).
- Field authorization only runs when the resource has an explicit
  `self.authorization_policy` and `authorization_client` isn't `nil`.

## Security

Because the same check filters the fields used for **param permitting and assignment**, a
field hidden from a user is also stripped from `create`/`update` — they can't set it by
crafting a request.
