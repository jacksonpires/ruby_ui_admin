# Ejecting & customizing

When configuration isn't enough, you can **eject** any engine file into your app and edit it.
A copy placed at the same path in your app's `app/` shadows the engine's version (Zeitwerk
loads your app's file first), so the framework picks up your customization automatically.

## The generator

```bash
# View components (app/components/ruby_ui_admin/views/*)
rails g ruby_ui_admin:eject --view index        # the index table/page
rails g ruby_ui_admin:eject --view show
rails g ruby_ui_admin:eject --view form
rails g ruby_ui_admin:eject --view layout       # alias for the Base layout (sidebar/topbar)
rails g ruby_ui_admin:eject --view field_value  # how field values render
rails g ruby_ui_admin:eject --view field_input  # how form inputs render

# Controllers (app/controllers/ruby_ui_admin/*)
rails g ruby_ui_admin:eject --controller resources    # CRUD behaviour
rails g ruby_ui_admin:eject --controller application  # base controller (auth hooks, etc.)

# The admin's own UI components (app/components/ruby_ui_admin/ui/*) — to restyle
rails g ruby_ui_admin:eject --ui icon
rails g ruby_ui_admin:eject --ui pagination
rails g ruby_ui_admin:eject --ui select
```

The file is copied verbatim to the same relative path in your app. Edit it there.

> **Restyling RubyUI primitives** (button, table, badge, card, sidebar, …): those aren't ejected
> from the gem — the admin renders **your app's** `RubyUI::*` components, so just edit them in
> `app/components/ruby_ui/*` (where RubyUI generated them). `--ui` only covers the components the
> gem owns: `icon`, `pagination`, `select`, and the `toast_*` family.

## How overriding works

The engine's controllers and Phlex components are autoloaded Ruby classes (e.g.
`RubyUIAdmin::Views::Index`, `RubyUIAdmin::ResourcesController`). Because your app's autoload
paths take precedence over an engine's, a file at the identical path in your app defines the
same class and **wins** — no configuration or monkey-patching required.

## Common customizations

| Goal | Eject |
|---|---|
| Change the sidebar/top bar/branding | `--view layout` |
| Tweak the index table markup | `--view index` |
| Change how a field type renders | `--view field_value` / `--view field_input` |
| Override CRUD redirects/messages | `--controller resources` |
| Add an authentication/authorization hook | `--controller application` |
| Restyle a RubyUI primitive (button/table/badge/…) | edit your app's `app/components/ruby_ui/*` |
| Restyle an admin-owned component (icon/pagination/select/toast) | `--ui icon` / `--ui pagination` / … |

> Eject only what you need — every ejected file is a copy you now maintain. Prefer
> [configuration](../getting-started/configuration.md) when it covers your use case.
