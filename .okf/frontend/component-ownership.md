---
type: Decision
title: Component ownership — host RubyUI primitives vs admin compositions
description: Primitives (Card, Button, Table, Sidebar, Combobox…) come from the host's RubyUI::*; only a handful of compositions live in RubyUIAdmin::UI.
tags: [rubyui, rendering, customization]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: claude-md
    title: CLAUDE.md — Components
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/CLAUDE.md
  - id: changelog
    title: CHANGELOG.md 0.1.1
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/CHANGELOG.md
---

# Rule

Engine views render the host's `RubyUI::*` for every primitive. Only components with no upstream
equivalent, or with a deliberate fork, live in `app/components/ruby_ui_admin/ui/`:[^claude-md]

| Component | Why it is ours |
|---|---|
| `Icon` | no upstream |
| `Pagination` (+ items/ellipsis/content) | orchestrates pagy and its helpers |
| `Select` / `NativeSelect` | wrapper taking an array `options:` |
| `Toast*` (region + subcomponents) | **intentional fork**: the region is *not* `turbo-permanent`, so flash re-renders on each Turbo Drive visit |
| `Base` | shared Phlex base |

When adding UI, reach for the host primitive first; add a `RubyUIAdmin::UI::*` only for a
composition.

# Consequences

- Hosts restyle primitives by editing their own `app/components/ruby_ui/*`; the eject generator's
  `--ui` only covers the admin-owned set (see [ejecting](/development/ejecting.md)).
- Compatibility follows RubyUI releases: 0.1.1 is verified against RubyUI 1.6.0; RubyUI's
  unreleased `main` (rewritten `Combobox`) is not supported yet.[^changelog]

Part of the [host-owned assets](/frontend/host-owned-assets.md) decision.
