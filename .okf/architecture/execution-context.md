---
type: Component
title: ExecutionContext and View
description: The single mechanism that evaluates every user-supplied proc in the DSL, exposing named readers and delegating to the Rails view context.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/execution_context.rb
tags: [dsl-core]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: ctx
    title: lib/ruby_ui_admin/execution_context.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/execution_context.rb
  - id: view
    title: lib/ruby_ui_admin/view.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/view.rb
---

# Overview

Nearly every option in the DSL accepts *either a literal or a proc*: `title`, `index_query`,
field `format_using`/`default`/computed blocks, `sortable:` lambdas, scope `scope`/`visible`,
action `message`/`visible`. All of them go through `ExecutionContext.new(target:, **readers).handle`:[^ctx]

- A non-callable target is returned as-is.
- A proc is `instance_exec`'d; each keyword passed becomes a reader method (`record`, `query`,
  `params`, `resource`, `current_user`, `view`…), so procs are written **zero-arity**
  (`-> { query.where(...) }`), not with block parameters.
- When a `view_context:` is passed, unknown methods (`link_to`, `main_app`, `*_path`) delegate to
  it — this is how computed fields can emit links.

Which readers exist depends on the call site; the docs for each DSL option list them.

# View value object

`RubyUIAdmin::View` wraps the current view symbol so lambdas can write `view == :show` **or**
`view.show?`, plus the groupings `form?` (new+edit) and `display?` (index+show).[^view]
