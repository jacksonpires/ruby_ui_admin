# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- CI on GitHub Actions: the full test suite runs on Ruby 3.2, 3.3, 3.4 and 4.0 × Rails 7.1, 7.2,
  8.0 and 8.1 (`gemfiles/rails_X.Y.gemfile`). Documented in the README's compatibility matrix.

## [0.1.1] - 2026-11-12

### Changed

- Verified compatibility with the latest releases: Ruby 4.0.9 (and 3.4.4), Rails 8.1.4.1,
  Phlex 2.4.1 / phlex-rails 2.4.0 and RubyUI 1.6.0 — documented in the README's new
  **Compatibility** section.
- README: note that RubyUI's unreleased `main` (rewritten `Combobox`) is not supported yet;
  fix the Development setup instructions.
- Development: pin `ruby_ui` to the released `~> 1.6` gem, sync the dummy app's RubyUI
  components to 1.6.0, and track `test/dummy/log`/`tmp` so the suite runs on a fresh clone.

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

[Unreleased]: https://github.com/jacksonpires/ruby_ui_admin/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/jacksonpires/ruby_ui_admin/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/jacksonpires/ruby_ui_admin/releases/tag/v0.1.0
