# RubyUI Admin

`ruby_ui_admin` is a Rails admin dashboard engine, rendered with
[RubyUI](https://rubyui.com) (Phlex) components, that even serves its own documentation as HTML
inside your app at `<mount>/docs` (e.g. `/admin/docs`).

![RubyUI Admin](/docs/assets/ruby-ui-admin.gif)

## What is RubyUI Admin?

RubyUI Admin turns your Active Record models into a complete, production-ready admin panel with
very little code. You point it at a model, describe its fields in a compact Ruby DSL, and you get
index / show / new / edit screens, pagination, filters, named scopes, bulk and custom actions,
dashboards, and authorization — all rendered server-side.

It grew out of three ideas:

- **A UI built on your app's [RubyUI](https://rubyui.com) (Phlex) components.** Every screen is
  composed from the same `RubyUI::*` components you've installed in your app — cards, tables,
  dialogs, toasts, a collapsible sidebar — so the admin matches your design system and tracks your
  RubyUI version. It's progressively enhanced with native Hotwire (Stimulus + Turbo).
- **A resource DSL inspired by [Avo](https://github.com/avo-hq/avo).** You configure the admin in plain Ruby
  classes — `fields`, `filters`, `scopes`, `actions`, policies — instead of generating and then
  hand-editing views. If you've used Avo, the shape will feel familiar.
- **Documentation you read inside the app.** The gem serves its own docs, rendered as HTML, at
  `<mount>/docs` (e.g. `/admin/docs`) — so you can look things up without leaving the admin. It's on
  in development by default and can be exposed in production (behind your auth gate) with
  `config.docs_enabled = true`.

### Requirements

The admin renders **your host app's RubyUI components**, so it expects:

- [RubyUI](https://rubyui.com) installed and its components generated into your app
  (`app/components/ruby_ui/*` as `RubyUI::*`), at a version compatible with the admin — run
  `rails g ruby_ui_admin:components` to generate exactly the ones the admin renders.
- A **JavaScript bundler/importmap** that registers RubyUI's Stimulus controllers (and the admin's
  own `rua--*` controllers — use `rails g ruby_ui_admin:assets` to copy them in), plus a **Tailwind
  build** that covers `app/components/ruby_ui/**` and the admin's views. You wire these into the
  admin layout via `config.head_assets`.

This makes the admin part of your app's UI rather than a self-contained bundle. (See
[Theming with RubyUI](docs/customization/theming-rubyui.md) and
[JavaScript](docs/customization/javascript.md).)

### Design principles

- **Server-rendered, progressively enhanced.** Everything works without JavaScript; Stimulus and
  Turbo only sharpen a few interactions (tabs, action modals, toasts, clickable rows).
- **Your design system, not a fork.** The admin uses your own `RubyUI::*` components; if one needs a
  change, change it in your app (or upstream a PR to RubyUI) — there's no vendored copy to maintain.
- **Plain Ruby, and ejectable.** Resources, policies, and actions are just classes; any view can be
  ejected and customized when you outgrow the defaults.

## Features

- Resources with a full field catalog, tabs & panels, and schema auto-discovery
- CRUD with pagination, named scopes, filters and index customization
- Custom actions (inline modals, with a no-JS page fallback) and bulk actions
- Dashboards with metric / chart / partial cards
- action_policy authorization: per-rule, record scopes, and field-level rules
- Generators (`install`, `components`, `assets`, `resource`, `controller`, `action`, `filter`,
  `policy`, `scope`, `dashboard`, `card`, `eject`, `locales`) and rake tasks
- Renders your app's RubyUI/Phlex components, enhanced with native Hotwire (Stimulus + Turbo)
- i18n (English + Brazilian Portuguese bundled)

See [`docs/`](docs/README.md) for the full documentation.

> Deferred / not yet built: inline association management (attach/detach + nested tables),
> grid/map index views, and a few reserved config options.

## Quick start

New to the gem? The [**practical guide**](docs/getting-started/practical-guide.md) is a
copy‑paste walkthrough from `rails new` to a working admin (two associated scaffolds,
configuration, resources and filters).

## Installation

Add to your `Gemfile`:

```ruby
gem "ruby_ui_admin"
```

Mount the engine in `config/routes.rb`:

```ruby
mount_ruby_ui_admin at: "/admin"
```

Configure it in `config/initializers/ruby_ui_admin.rb`:

```ruby
RubyUIAdmin.configure do |config|
  config.app_name = "My Admin"
  config.current_user_method { current_user }     # resolve the signed-in admin
  config.authenticate_with { redirect_to main_app.login_path unless current_user }
  config.authorization_client = :action_policy
  config.explicit_authorization = false           # allow rules a policy doesn't define
end
```

## Defining a resource

Resources live in `app/ruby_ui_admin/resources` and are namespaced under `RubyUIAdmin::Resources`:

```ruby
module RubyUIAdmin
  module Resources
    class Post < RubyUIAdmin::BaseResource
      self.title = :title
      self.includes = [:user]
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

## Authorization

Policies use action_policy and live in `app/ruby_ui_admin/policies`
(`RubyUIAdmin::Policies::*`), inheriting `RubyUIAdmin::BasePolicy`:

```ruby
module RubyUIAdmin
  module Policies
    class PostPolicy < RubyUIAdmin::BasePolicy
      def index? = true
      def show? = true
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

## Documentation

Full documentation lives in [`docs/`](docs/README.md).

## Development

```bash
bin/setup            # bundle install
bundle exec rake test    # run the minitest suite against test/dummy
```

## License

MIT.
