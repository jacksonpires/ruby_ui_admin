---
type: Convention
title: Native Hotwire only — no vanilla JS
description: All interactivity is a scoped Stimulus controller or a native Turbo feature; document-level listeners and hand-rolled fetches are not allowed.
tags: [hotwire, assets]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude-md
    title: CLAUDE.md — PRIORITY use native Hotwire
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/CLAUDE.md
  - id: actions-controller
    title: ActionsController#show / #process_response
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/app/controllers/ruby_ui_admin/actions_controller.rb
---

# Rule

Every interactive behaviour is either a **Stimulus controller** (scoped to its element,
`connect`/`disconnect` lifecycle) or a **Turbo** feature. No `document.addEventListener`, no
manual DOM scripts — they duplicate listeners and break on Turbo visits.[^claude-md] Prefer the
Turbo-native option over a custom controller (`<turbo-frame loading="lazy">` over `fetch`,
`data-turbo-confirm` over a custom dialog).

The admin is progressively enhanced: everything works without JS; Hotwire improves it.

# Controller families

- `rua--*` — ours: `tabs`, `dialog`, `bulk-select`, `row-link`, `confirm`. New behaviour goes
  here.
- `ruby-ui--*` — RubyUI's (sidebar/sheet, combobox, toast/toaster).

The `rua--` double-dash breaks Stimulus **outlet** property names, so cross-controller reads use
shared `data-*` hooks instead (e.g. `rua--dialog` reading the bulk-select checkboxes).[^claude-md]

# Turbo patterns in use

- POST → redirect responses are **303 See Other** so Turbo follows them as GET visits.[^actions-controller]
- Lazy tabs and the action modal are **Turbo Frames**. The modal frame loads the form fragment
  (static lazy `src` for single-record; `rua--dialog#open` sets `src` from the checked rows for
  bulk), and the form carries `data-turbo-frame="_top"` so submit breaks out into a full visit
  with flash.[^claude-md]
- Goal: drop remaining `data-turbo="false"` opt-outs as behaviours become Turbo-safe.

Related: [custom actions](/dsl/actions.md), [host-owned assets](/frontend/host-owned-assets.md).
