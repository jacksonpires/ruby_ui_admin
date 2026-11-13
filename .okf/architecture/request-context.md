---
type: Component
title: Request context and current user
description: How each admin request resolves current_user/true_user, authenticates, and scopes locale/timezone via RubyUIAdmin::Current.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/application_controller.rb
tags: [authentication, security]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: app-controller
    title: app/controllers/ruby_ui_admin/application_controller.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/application_controller.rb
  - id: config
    title: lib/ruby_ui_admin/configuration.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/configuration.rb
---

# Overview

`RubyUIAdmin::ApplicationController` (inherits `ActionController::Base`, **not** the host's
`ApplicationController`) runs every request inside `with_current_context`:[^app-controller]

1. Sets `RubyUIAdmin::Current.request/user/true_user` (an `ActiveSupport::CurrentAttributes`),
   reset in `ensure`.
2. Wraps the action in `Time.use_zone(config.timezone)` and `I18n.with_locale(config.locale)`
   when set.

`before_action :authenticate_admin!` simply `instance_exec`s `config.authenticate_with` in the
controller — the gem has no auth of its own.

# Resolving the user

- `current_user`: `config.current_user_method` block (instance-exec'd in the controller) or, if
  unset, the Warden/Devise fallback `request.env["warden"]&.user`.[^app-controller][^config]
- `true_user`: the real user behind an impersonation; defaults to `current_user`. It is passed to
  every [authorization adapter](/authorization/adapter-architecture.md) so policies can gate on it.

`NotAuthorizedError` is rescued into a plain-text **403**.

Test-suite note: the dummy app resolves `current_user` as `User.first`, which is why tests create
the acting user first (see [testing conventions](/development/testing-conventions.md)).
