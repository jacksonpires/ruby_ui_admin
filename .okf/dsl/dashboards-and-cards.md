---
type: Component
title: Dashboards and cards
description: BaseDashboard declares cards in a grid; card types (metric, chart, partial) are subclassed by host cards that override `query`.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_dashboard.rb
tags: [dsl-core]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: dashboard
    title: lib/ruby_ui_admin/base_dashboard.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/base_dashboard.rb
  - id: card
    title: lib/ruby_ui_admin/cards/base_card.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/cards/base_card.rb
---

# Overview

Host dashboards (`RubyUIAdmin::Dashboards::*`) live in `app/ruby_ui_admin/dashboards`, are
discovered by `DashboardManager` (same dedupe-by-name pattern as the
[resource registry](/architecture/resource-registry.md)) and served at `/dashboards/:dashboard_id`.
`id` defaults to the underscored class name; `grid_columns` defaults to 3.[^dashboard]

Cards mirror the filters pattern: `MetricCard`, `ChartCard` and `PartialCard` are base types that
`register_type`, and host cards (`RubyUIAdmin::Cards::*`) inherit one and override `query`.
`width` is in grid columns (default 1).[^card] Options passed with `card Klass, foo: 1` reach the
instance as `options`.
