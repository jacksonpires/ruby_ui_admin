# Dashboards & Cards

Dashboards group cards (metrics, charts, custom panels). Define them in
`app/ruby_ui_admin/dashboards` under `RubyUIAdmin::Dashboards`, and cards in
`app/ruby_ui_admin/cards` under `RubyUIAdmin::Cards`.

```ruby
module RubyUIAdmin
  module Dashboards
    class Overview < RubyUIAdmin::BaseDashboard
      self.name = "Overview"
      self.description = "Key metrics at a glance."
      self.grid_columns = 3

      def cards
        card RubyUIAdmin::Cards::PostsCount
        card RubyUIAdmin::Cards::PostsByStatus
      end
    end
  end
end
```

Dashboards appear in the sidebar and are served at `/admin/dashboards/<id>` (the id
defaults to the underscored class name, overridable with `self.id =`).

## Cards

Inherit from a card base and implement `query`:

```ruby
module RubyUIAdmin
  module Cards
    class PostsCount < RubyUIAdmin::Cards::MetricCard
      self.label = "Total posts"
      def query = Post.count
    end

    class PostsByStatus < RubyUIAdmin::Cards::ChartCard
      self.label = "Posts by status"
      def query = Post.group(:status).count   # {label => number}
    end

    class Welcome < RubyUIAdmin::Cards::PartialCard
      self.label = "Welcome"
      def query = "<p>Hello!</p>"             # raw HTML
    end
  end
end
```

| Card base | `query` returns | Rendered as |
|---|---|---|
| `MetricCard` | a value | a large number (with optional `prefix:`/`suffix:`) |
| `ChartCard` | a Hash `{label => number}` | horizontal bars (no JS dependency) |
| `PartialCard` | an HTML String | rendered as-is |

Set `self.width = 2` on a card to make it span more grid columns.

## Generators

```bash
rails g ruby_ui_admin:dashboard Overview
rails g ruby_ui_admin:card PostsCount --type metric   # metric | chart | partial
```
