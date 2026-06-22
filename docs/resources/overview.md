# Resources — Overview

A resource maps an ActiveRecord model to the admin UI. Resources live in
`app/ruby_ui_admin/resources` and are namespaced under `RubyUIAdmin::Resources`.

```ruby
module RubyUIAdmin
  module Resources
    class Post < RubyUIAdmin::BaseResource
      self.title = :title                 # attribute (or lambda) used as the record label
      self.includes = [:user]             # eager-loaded associations
      self.model_class = Post             # optional; inferred from the class name
      self.index_query = -> { query.order(created_at: :desc) }  # optional default scope
      self.authorization_policy = RubyUIAdmin::Policies::PostPolicy

      def fields
        field :id, as: :id
        field :title, as: :text, link_to_record: true, sortable: true
        field :body, as: :text, only_on: %i[show new edit]
        field :published, as: :boolean
        field :user, as: :belongs_to
        field :created_at, as: :date_time, only_on: %i[index show]
      end
    end
  end
end
```

## Class options

| Option | Purpose |
|---|---|
| `self.title` | Attribute symbol or lambda used as the record's display label |
| `self.includes` | Associations to eager-load on the index query |
| `self.model_class` | Override the inferred model class |
| `self.index_query` | Lambda returning the default index scope (`query` is available) |
| `self.authorization_policy` | The action_policy policy class for this resource |
| `self.visible_on_sidebar` | Hide the resource from the sidebar when `false` |
| `self.description` | Subtitle shown under the index title |
| `self.record_selector` | Set `false` to hide the bulk-select checkbox column |
| `self.row_controls` | `->(record) { ... }` rendering extra per-row controls on the index (helpers: `show_button(record)`, `edit_button(record)`, `create_button`, `control_link`) |
| `self.row_controls_config` | Layout for the row-controls cell: `{ placement: :left/:right, float: true, show_on_hover: true }` |
| `self.countless` | Paginate without a `COUNT` query (pagy countless) — for very large tables. Can also be enabled globally via `config.pagination` |
| `self.remove_scope_all` | Hide the "All" scope tab (use with a default [scope](scopes.md)) |

## Fields

`field :name, as: :type, **options` — see the [field catalog](../fields/overview.md) for all
types and options, and [tabs & panels](tabs-panels.md) for grouping. Fields can also be
auto-derived from the schema with `discover_columns` / `discover_associations`.
