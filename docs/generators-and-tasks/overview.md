# Generators & Rake tasks

## Generators

| Command | Creates |
|---|---|
| `rails g ruby_ui_admin:install [--path admin]` | `config/initializers/ruby_ui_admin.rb` and mounts the engine in `config/routes.rb` |
| `rails g ruby_ui_admin:resource Post [--model-class Post]` | `app/ruby_ui_admin/resources/post.rb` with fields derived from the model schema |
| `rails g ruby_ui_admin:action PublishPosts [--standalone]` | `app/ruby_ui_admin/actions/publish_posts.rb` |
| `rails g ruby_ui_admin:filter status --type select` | `app/ruby_ui_admin/filters/status_filter.rb` (`--type text\|select\|boolean`) |
| `rails g ruby_ui_admin:policy Post` | `app/ruby_ui_admin/policies/post_policy.rb` |
| `rails g ruby_ui_admin:scope Published` | `app/ruby_ui_admin/scopes/published.rb` |
| `rails g ruby_ui_admin:dashboard Overview` | `app/ruby_ui_admin/dashboards/overview.rb` |
| `rails g ruby_ui_admin:card UsersCount --type metric` | `app/ruby_ui_admin/cards/users_count.rb` |
| `rails g ruby_ui_admin:eject --view index` | copies an engine view/controller/UI file into your app to customize (see [Ejecting](../customization/ejecting.md)) |
| `rails g ruby_ui_admin:components` | generates the RubyUI components the admin renders (drives `ruby_ui:component`, one per command; safe to re-run) |
| `rails g ruby_ui_admin:assets` | sets up the admin's Stimulus controllers — copies them for bundlers, or pins the engine-served entrypoint for importmap (see [JavaScript](../customization/javascript.md)) |
| `rails g ruby_ui_admin:locales` | copies the bundled locale files into `config/locales` (see [i18n](../getting-started/internationalization.md)) |
| `rails g ruby_ui_admin:controller Buyer` | per-resource controller for CRUD lifecycle-hook overrides (see [Controllers](../customization/controllers.md)) |

### Resource generator

The resource generator introspects the model and writes one `field` line per column and
association — database columns map to field types (`string → :text`, `text → :textarea`,
`boolean → :boolean`, `datetime → :date_time`, `json → :code`, …), foreign keys become
`:belongs_to`, and associations become `:has_many` / `:has_one` / `:has_and_belongs_to_many`.
Long-form fields (`:textarea`, `:code`) are generated with `only_on: %i[show new edit]` so they
don't clutter the index table — drop that option to show them everywhere. Edit the generated file to
taste; it's a starting point, not a lock-in.

Namespaced names are supported (e.g. `ruby_ui_admin:action Users::ResetPassword` →
`app/ruby_ui_admin/actions/users/reset_password.rb`).

## Rake tasks

| Task | Description |
|---|---|
| `rake ruby_ui_admin:version` | Print the installed version |
| `rake ruby_ui_admin:install` | Run the install generator |
| `rake ruby_ui_admin:tailwind_source` | Extract the admin's Tailwind classes into `app/assets/tailwind/ruby_ui_admin_classes.html` for `@source` (commit it; re-run on upgrade) |
| `rake ruby_ui_admin:all_resources` | Generate a resource for every ActiveRecord model |
| `rake ruby_ui_admin:routes` | List the mounted admin routes |
