# CLAUDE.md

Guidance for working in the `ruby_ui_admin` gem.

## Testing conventions (minitest)

- **No `setup` or `teardown` blocks.** Every test must be **self-contained**: it creates all
  the data it needs inline and restores any global state it touches.
- Use the explicit helpers in `test/test_helper.rb` (called from within a test, never run
  implicitly):
  - `acting_admin` / `acting_member` — create the acting user (the dummy resolves
    `current_user` as `User.first`, so create it first in the test).
  - `with_config(**opts) { ... }` — temporarily override `RubyUIAdmin.configuration` and
    restore it afterwards (use this instead of mutating config in `setup`/`teardown`).
- Restore any other global mutation inside the test with `ensure` (e.g. redefining a policy
  method). Do not rely on a `teardown` block.
- Generator tests (`Rails::Generators::TestCase`) call `prepare_destination` at the start of
  each test instead of `setup :prepare_destination`.
- Tests must be order-independent — verify with multiple seeds when in doubt:
  `bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require File.expand_path(f) }' -- --seed N`

## Running the suite

```bash
bundle exec rake test
```

The suite runs against the dummy app in `test/dummy` (which is part of the test setup — do
not delete it). To prepare its database: `cd test/dummy && bin/rails db:prepare`.

## Dummy app & assets gotchas

- **New dummy DB columns**: the test DB loads from `test/dummy/db/schema.rb`, not from running
  migrations. After adding a migration under `test/dummy/db/migrate`, also edit `schema.rb`
  (add the column and bump the `version:`) or the column won't exist in tests.
- **Never run ad-hoc `Model.create!` against `RAILS_ENV=test` outside a transaction** (e.g. a
  `bin/rails runner` debug script). It commits to the test sqlite DB and pollutes later runs,
  causing confusing cross-test failures. Clean up with `delete_all` if it happens.
- **Assets come from the HOST (Option 3 — done on the gem side; see the
  `option3-host-rubyui-migration` memory).** The admin renders the host's `RubyUI::*` components, so
  the host owns the CSS (its Tailwind build, scanning `app/components/ruby_ui/**` + the admin views,
  incl. tokens like `success`/`warning`) and JS (its bundler/importmap registering RubyUI's
  controllers + our `rua--*`). The host wires both into the layout via **`config.head_assets`** (a
  proc rendered by `render_head_assets`). The engine still ships/serves a precompiled
  `application.css` (built via `rake ruby_ui_admin:build_assets`) — the dummy reuses it for tests —
  but it is no longer the source of truth for a real host.
- **PRIORITY — use native Hotwire, never hand-written vanilla JS.** All interactive behaviour
  MUST be a **Stimulus controller** (scoped to its element, lifecycle-managed via
  `connect`/`disconnect`) or a **Turbo** feature (Turbo Drive, **Turbo Frames** for lazy/partial
  loads, **Turbo Streams** for server-driven updates, and Turbo's **native** `data-turbo-method` /
  `data-turbo-confirm`). **Do not** add `document`-level `addEventListener`/manual-DOM vanilla JS:
  it conflicts with Rails/Hotwire (Turbo navigations, duplicate/global listeners, UJS) and breaks
  on Turbo visits. JS/Turbo now come from the **host's bundler** (Option 3); the host registers
  RubyUI's controllers + our `rua--*` via `config.head_assets`. When you convert a behaviour, prefer the Turbo-native option over a custom controller
  (e.g. Turbo Frame `loading="lazy"` instead of a `fetch`; `data-turbo-confirm` instead of a custom
  AlertDialog) and aim to drop the `data-turbo="false"` opt-out once behaviours are Turbo-safe.
- **Components: host `RubyUI::*` for primitives; our `RubyUIAdmin::UI::*` only for compositions.**
  After the Option 3 migration, the engine views render the host's `RubyUI::*` (Card, Badge, Button,
  Link/InlineLink, Checkbox, Input, Textarea, Table, Sidebar, Combobox, …). The only components that
  still live in `app/components/ruby_ui_admin/ui/` are our own: **Icon** (no upstream), **Pagination**
  (pagy orchestrator + helpers), **Select**/**NativeSelect** (array-`options:` wrapper), **Toast***
  (region+sub — intentional fork: non-`turbo-permanent` for Turbo Drive), and **Base**. The JS is two
  controller families: **`rua--*`** (ours: `rua--tabs`/`dialog`/`bulk-select`/`row-link`/`confirm`)
  and **`ruby-ui--*`** (RubyUI's). The gem still ships the `rua--*` + vendored controllers
  under `public/ruby-ui-admin-assets/controllers/`, but they're loaded by the **host's** bundler now.
  Gotcha: the admin's flash uses RubyUI **Toast** (our `RubyUIAdmin::UI::Toast*`), so the host must
  register `ruby-ui--toaster`/`ruby-ui--toast` even if its own app doesn't use RubyUI Toast (the gem
  ships those controllers; otherwise toasts silently don't show).
  New behaviour → a `rua--*` Stimulus controller. **Turbo is on:**
  POST→redirect responses use **303 (`see_other`)**, the toaster region is **not** `turbo-permanent`
  (flash re-renders each visit), and the lazy loads (tabs **and** the action modal) are
  **Turbo Frames** — no more hand-rolled `fetch`. The action modal's `<turbo-frame>` loads the
  form fragment (non-bulk: static lazy `src`; bulk: `rua--dialog#open` sets `src` from the checked
  rows), and the form carries `data-turbo-frame="_top"` so the submit breaks out into a full visit
  (POST→303→redirect+flash) instead of reloading just the frame.
  Caveat: in a Turbo+importmap host, entering the engine must be a full load (`data-turbo="false"`
  on the host's links to it) or the engine's importmap won't apply.
  Note: the `rua--` double-dash namespace breaks Stimulus **outlet** property
  names, so prefer shared `data-*` hooks for cross-controller reads (see `rua--dialog` ↔ bulk select).
- **Editing gem `lib/` requires a server restart** (required once); `app/` (Phlex components,
  controllers) and `public/` JS are picked up on reload. In dev, `BaseResource`/`BaseDashboard`
  `descendants` accumulates stale reloaded classes — the managers dedupe by name to avoid
  duplicate nav entries.

## Project layout (quick reference)

- Framework code: `lib/ruby_ui_admin/**` (resources, fields, filters, scopes, actions, dashboards,
  cards, services, menu, **authorization**, `view.rb`, engine, configuration). Loaded via explicit
  `require`s.
- **Authorization is adapter-based** (`config.authorization_client`): `Services::AuthorizationService`
  is a facade that resolves an adapter via `RubyUIAdmin::Authorization.adapter_class` —
  `:action_policy` (default), `:pundit`, `:cancancan`, or a custom `Authorization::Adapter` subclass;
  `nil` disables. Adapters live in `lib/ruby_ui_admin/authorization/` (Pundit/CanCanCan required
  lazily). `BasePolicy` is the action_policy base; the `manage?`/`explicit_authorization` fallback is
  action_policy/Pundit only (CanCanCan denies what its Ability doesn't grant; no field-level rules).
  See `docs/authorization/adapters.md`.
- Engine UI: `app/components/ruby_ui_admin/**` (Phlex) and `app/controllers/ruby_ui_admin/**`.
- Host-defined admin files live under `app/ruby_ui_admin/{resources,actions,filters,scopes,
  policies,cards,dashboards}` (`RubyUIAdmin::Resources::*`, etc.).
- Docs live in `docs/` (start at `docs/README.md`; the copy-paste onboarding is
  `docs/getting-started/practical-guide.md`).
- **In-app docs browser**: gated by `config.docs_enabled` (default `:local` → dev/test only, open;
  `true` → all envs incl. production, behind `authenticate_admin!`; `false` → never; or a callable —
  resolved by `Configuration#docs_enabled?`). When enabled the engine mounts `<mount>/docs` (e.g.
  `/admin/docs`), which renders the gem's `docs/*.md` as HTML. The route is drawn at boot from
  `docs_enabled?` (changing it needs a restart); `DocsController` skips auth only in local envs.
  It reads only `.md` files under `Engine.root/docs` (path-traversal guarded),
  renders via **kramdown GFM** (required lazily; no Rouge — its kramdown formatter spams deprecation
  warnings), rewrites relative `*.md` links to the docs route, and renders the self-contained
  `Views::Docs` Phlex page (own embedded CSS — deliberately NOT the admin layout / host RubyUI/Tailwind,
  so it works in a half-wired host). Hosts add `kramdown` + `kramdown-parser-gfm` to their dev group.
