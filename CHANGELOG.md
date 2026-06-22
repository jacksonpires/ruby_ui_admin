# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-15

### Added

- Initial release of `ruby_ui_admin` — a Rails admin dashboard engine rendered with
  the host app's RubyUI (Phlex) components.
- Resource DSL (fields, filters, scopes, actions, policies) inspired by Avo.
- CRUD with pagination, named scopes, filters, and index customization.
- Custom actions (inline modals with a no-JS page fallback) and bulk actions.
- Dashboards with metric / chart / partial cards.
- Adapter-based authorization (`action_policy` default, `pundit`, `cancancan`, or custom),
  including per-rule, record-scope, and field-level rules.
- Generators (`install`, `components`, `assets`, `resource`, `controller`, `action`,
  `filter`, `policy`, `scope`, `dashboard`, `card`, `eject`, `locales`) and rake tasks.
- In-app documentation browser served at `<mount>/docs`.
- i18n bundled (English and Brazilian Portuguese).

[Unreleased]: https://github.com/jacksonpires/ruby_ui_admin/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jacksonpires/ruby_ui_admin/releases/tag/v0.1.0
