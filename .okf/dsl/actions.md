---
type: Component
title: Custom actions
description: BaseAction — form-backed operations on one, many or no records, run through ActionsController with a response object that becomes flash + 303 redirect.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_action.rb
tags: [avo-parity, hotwire, authorization]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: base-action
    title: lib/ruby_ui_admin/base_action.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_action.rb
  - id: controller
    title: app/controllers/ruby_ui_admin/actions_controller.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/actions_controller.rb
---

# Overview

A resource attaches actions with `action Klass, arguments: {...}` inside `def actions`. The URL
id is `action_key` — the class path under `RubyUIAdmin::Actions::`, underscored
(`Users::ResetPassword` → `users_reset_password`).[^base-action]

# Lifecycle

1. **GET `show`** renders the form. With `?fragment=1` it returns only the form, wrapped in the
   modal's `<turbo-frame>` — the action's `fields` are evaluated only when the modal opens. Without
   JS, the same route is a full page (no-JS fallback).[^controller]
2. **POST `run`** authorizes `act_on?` against the first selected record (or the model class when
   none), collects `params[:fields]` into an indifferent hash, and calls `handle`.
3. `handle` supports **two signatures**, detected by reflection on its parameters: keyword style
   (`handle(query:, fields:, current_user:, resource:, **)` — only accepted keys are passed) and
   positional `handle(args)`.[^controller]
4. The response helpers (`succeed`, `error`, `inform`, `warn`, `redirect_to`, `reload`,
   `download`, `silent`, `keep_modal_open`) mutate a response hash; the controller turns it into
   flash + **303** redirect (or `send_data`). An action that sets no message still flashes
   "ran successfully" unless `silent` — Avo parity.[^controller]

Bulk vs single: one selected record ⇒ view `:show`, otherwise `:index`. The resource is hydrated
with the first record so `resource.record` works inside action `fields`.

Inside `handle`, bare `*_path`/`*_url` helpers resolve against the engine routes first, then
`main_app`.[^base-action] The modal/frame mechanics are in [Hotwire only](/frontend/hotwire-only.md).
