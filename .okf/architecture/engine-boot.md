---
type: Component
title: Engine boot and host integration
description: How the Rails engine wires itself into a host — inflections, the app/ruby_ui_admin autoload namespace, the mount helper and the Rack::Static asset mount.
resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/engine.rb
tags: [boot, zeitwerk, routing]
generated:
  by: claude-code/claude-opus-5-5
  at: 2026-11-13T12:00:00Z
sources:
  - id: engine
    title: lib/ruby_ui_admin/engine.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin/engine.rb
  - id: entry
    title: lib/ruby_ui_admin.rb
    resource: https://github.com/jacksonpires/ruby_ui_admin/blob/main/lib/ruby_ui_admin.rb
---

# Overview

`RubyUIAdmin::Engine` is an isolated-namespace Rails engine. Four initializers carry the
non-obvious parts of host integration:[^engine]

| Initializer | What it does | Why it matters |
|---|---|---|
| `ruby_ui_admin.inflections` (before `set_autoload_paths`) | Registers the `UI` acronym for both ActiveSupport and every Zeitwerk loader (`ruby_ui_admin`→`RubyUIAdmin`, `ui`→`UI`, `dsl`→`DSL`) | Routing camelizes `ruby_ui_admin/resources` through ActiveSupport, autoloading goes through Zeitwerk — both must agree or controllers/components fail to resolve |
| `ruby_ui_admin.autoload` | Pushes the host's `app/ruby_ui_admin/` as a Zeitwerk root **namespaced under `RubyUIAdmin`**, and removes it from the plain autoload paths | So `app/ruby_ui_admin/resources/post.rb` defines `RubyUIAdmin::Resources::Post` |
| `config.to_prepare` | `reset_resource_manager` + `boot` on every reload | Keeps the [resource registry](/architecture/resource-registry.md) in sync in development |
| `ruby_ui_admin.routing` | Adds `mount_ruby_ui_admin(at:)` to the routing mapper | Default mount comes from `config.root_path` (`/admin`) |

The engine also mounts `Rack::Static` at `/ruby-ui-admin-assets`, serving the gem's `public/`
**outside** the engine mount and undigested — that is what lets an importmap host load the
shipped Stimulus controllers' relative imports (see [host-owned assets](/frontend/host-owned-assets.md)).

`pagy/extras/countless` is required at engine boot, before host initializers, because hosts that
freeze `Pagy::DEFAULT` would otherwise hit a `FrozenError` when the extra loads later.[^engine]

# Framework code is required, not autoloaded

Everything under `lib/ruby_ui_admin/**` (base classes, fields, filters, adapters…) is loaded by
explicit `require`s in `lib/ruby_ui_admin.rb`.[^entry] Consequence: editing `lib/` needs a server
restart, while `app/` (controllers, Phlex views) reloads — see
[dev-reload gotchas](/development/dev-reload-gotchas.md).
