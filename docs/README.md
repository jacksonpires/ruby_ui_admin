# RubyUI Admin — Documentation

> The README covers the essentials. This folder holds the full documentation, split by topic.

> **Read these inside your app.** The admin can serve this documentation rendered as HTML at
> `<mount>/docs` (e.g. `/admin/docs`). By default (`config.docs_enabled = :local`) it's mounted in
> development/test only; set `config.docs_enabled = true` to expose it in production too (where it
> runs behind the admin's auth gate). Add `kramdown` + `kramdown-parser-gfm` to the bundle of the
> target environment — see
> [Configuration › In-app docs browser](getting-started/configuration.md#in-app-docs-browser).

## Getting started
- [Practical guide: a working admin from scratch](getting-started/practical-guide.md) — copy‑paste, start here
- [Installation](getting-started/installation.md)
- [Configuration](getting-started/configuration.md)
- [Authentication](getting-started/authentication.md)
- [Internationalization (i18n)](getting-started/internationalization.md)

## Resources
- [Overview](resources/overview.md)
- [Tabs & panels](resources/tabs-panels.md)
- [Index customization](resources/index-customization.md)
- [Associations](resources/associations.md)
- [Scopes](resources/scopes.md)

## Fields
- [Overview & field catalog](fields/overview.md)

## Actions
- [Overview](actions/overview.md)

## Filters
- [Overview & types](filters/overview.md)

## Dashboards & cards
- [Overview](dashboards/overview.md)

## Authorization
- [Authorization adapters (action_policy / Pundit / CanCanCan / custom)](authorization/adapters.md)
- [action_policy integration](authorization/action-policy.md)
- [Policies](authorization/policies.md)
- [Authorization scopes](authorization/scopes.md)
- [Field-level authorization](authorization/field-authorization.md)
- [Explicit authorization mode](authorization/explicit-mode.md)

## Customization
- [Theming with RubyUI](customization/theming-rubyui.md)
- [JavaScript](customization/javascript.md)
- [Custom controllers & lifecycle hooks](customization/controllers.md)
- [Ejecting & customizing](customization/ejecting.md)

## Generators & rake tasks
- [Overview](generators-and-tasks/overview.md)
