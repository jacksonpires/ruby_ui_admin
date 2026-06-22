# Scopes

Named scopes partition a resource's index into tabs. Define them in
`app/ruby_ui_admin/scopes` under `RubyUIAdmin::Scopes`, then declare them on the resource.

```ruby
module RubyUIAdmin
  module Scopes
    class Published < RubyUIAdmin::Scopes::BaseScope
      self.name = "Published"
      self.description = "Only published posts"          # optional: tooltip on the scope tab
      self.scope = -> { query.where(published: true) }   # lambda, or...
      # self.scope = :published                          # ...a Symbol = the model's named scope
      self.default = true            # optional: applied when no scope is selected
      # self.visible = -> { user.admin? }  # optional: show the tab conditionally
    end
  end
end
```

Attach to a resource:

```ruby
def scopes
  scope RubyUIAdmin::Scopes::Published, default: true   # mark default at attachment
  scope RubyUIAdmin::Scopes::Drafts
end

# Hide the "All" tab (pair with a default scope):
self.remove_scope_all = true
```

## Behaviour

- The index renders a tab bar: **All** + one tab per scope.
- **`self.scope`** is a lambda (receiving `query` — the base relation, already narrowed by the
  policy scope — and `params`) returning a narrowed relation, **or** a Symbol naming a model
  scope/class method (e.g. `:published` → `Post.published`).
- Selecting a tab reloads the index with `?scope=<key>` (the key is the underscored class
  name, e.g. `Published` → `published`). `?scope=all` clears any scope.
- **`self.default = true`** (or `scope Klass, default: true` at attachment) makes a scope apply
  when no `?scope=` param is present; otherwise the index opens on **All**. The attachment option
  wins over the class setting.
- **`self.remove_scope_all = true`** on the resource hides the **All** tab (use with a default scope).
- **`self.visible`** (a lambda) hides a scope's tab when it returns false.
- Scopes compose with the policy scope and [filters](../filters/overview.md): policy scope →
  named scope → filters → sorting. The active scope is preserved when applying filters and
  paginating.

## Generator

```bash
rails g ruby_ui_admin:scope Published
```
