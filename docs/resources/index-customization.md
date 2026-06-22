# Index customization

## Custom header controls (`index_controls`)

Add your own buttons/links to the index header with `self.index_controls`, a block rendered
in the index view:

```ruby
class Post < RubyUIAdmin::BaseResource
  self.index_controls = -> { control_link("Invite buyer", invite_path) }
end
```

The block is evaluated inside the index component, so it has access to:

- **`control_link(label, href, variant: :outline)`** — a button-styled link (`:outline` or
  `:primary`). The common case.
- **`create_button(label: nil)`** — a primary "New" link for this resource.
- **Phlex element methods** (`a`, `button`, `div`, …) for full control.
- **Route helpers** via the mounted engine proxy, e.g. `ruby_ui_admin.resources_users_path`.
- **`@resource`** — the current resource instance.

## Per-row controls (`row_controls`)

`self.row_controls = ->(record) { ... }` adds controls to each row's actions cell. The block
receives the row's `record` and is evaluated in the index component, so it has the same helpers
plus **`show_button(record, label: nil)`** and **`edit_button(record, label: nil)`**:

```ruby
self.row_controls = ->(record) { show_button(record, label: "Preview") }

# Layout of the controls cell:
self.row_controls_config = { placement: :right, float: true, show_on_hover: true }
```

Examples:

```ruby
# Two controls, mixing the helper and raw Phlex:
self.index_controls = lambda do
  control_link("Export CSV", "/exports/posts.csv")
  a(href: ruby_ui_admin.resources_users_path, class: "text-sm text-primary hover:underline") { "Manage users" }
end
```

Custom controls render alongside the built-in **New** button and any standalone actions.

> Use a `lambda`/`proc` with **no arguments** and read `@resource` directly inside the block.

## Bulk selection

When a resource has bulk actions, the index shows per-row selection checkboxes (plus a
"select all"). `self.record_selector` (default `true`) controls this — set it to `false` to
hide the selection column even when bulk actions exist:

```ruby
self.record_selector = false
```

With no bulk actions, there's nothing to select, so no checkboxes render regardless.

## Reserved options (no effect yet)

| Option | Intended purpose |
|---|---|
| `self.default_view_type` | Default index layout (`:table`, `:grid`, `:map`). Only `:table` is implemented. |

Setting it is harmless; it simply has no effect today.
