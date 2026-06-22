# JavaScript

The admin's interactive behaviour is built with native **Hotwire** — **Stimulus controllers** plus
**Turbo** (Drive + Frames) — that **progressively enhance** the server-rendered HTML. Everything
works without JavaScript; Hotwire only improves a few interactions.

## How it's delivered

The admin renders **your host app's RubyUI components**, so the JavaScript comes from **your app's
bundler/importmap** — the admin doesn't ship its own runtime. It needs two sets of controllers
registered:

- The admin's own controllers, prefixed **`rua--*`**: `rua--tabs`, `rua--dialog` (action modals),
  `rua--bulk-select`, `rua--row-link`, `rua--confirm` (delete confirmation).
- **`ruby-ui--toaster` / `ruby-ui--toast`** — the admin renders RubyUI Toast for flash messages
  **even if your app doesn't use RubyUI Toast**, so you probably won't already have these (the
  toaster is patched for server-rendered flash). The other `ruby-ui--*` it uses (`ruby-ui--sidebar`
  /`ruby-ui--sheet`, `ruby-ui--combobox`, …) are the same ones you already use for RubyUI elsewhere
  — combobox/popover depend on `@floating-ui/dom`, so make sure it's available.

**Don't wire these by hand.** The gem ships them flat under
`public/ruby-ui-admin-assets/controllers/` plus an `index.js` that registers each under the right
identifier. The `ruby_ui_admin:assets` generator copies the whole directory into your app and tells
you the one import to add:

```bash
bin/rails generate ruby_ui_admin:assets
# Bundler (esbuild/jsbundling/vite): copies to app/javascript/ruby_ui_admin/,
#   then add to application.js:  import "./ruby_ui_admin"
# Importmap + Propshaft: does NOT copy — pins the engine-served (undigested) entrypoint:
#   config/importmap.rb:  pin "ruby_ui_admin", to: "/ruby-ui-admin-assets/controllers/index.js"
#   application.js:       import "ruby_ui_admin"
```

Why importmap doesn't copy: Propshaft content-digests copied files, but `index.js`'s relative
`./x.js` imports resolve to the *undigested* URLs (import maps only remap bare specifiers), which
Propshaft won't serve → 404. The engine serves the same files **undigested** via Rack::Static, so
relative imports work there and `@hotwired/stimulus`/`@hotwired/turbo` resolve through your own
import map.

Avoid translating the files into `controllers/rua/…` folders and running
`stimulus:manifest:update` — the manifest would derive the wrong identifiers. The shipped `index.js`
already registers everything correctly; you just import it.

> Symptom: if flash toasts don't appear after an action, `ruby-ui--toaster` / `ruby-ui--toast`
> are missing from your bundle — re-run `ruby_ui_admin:assets` and re-add the import.

You wire these (plus your stylesheet) into the admin layout through **`config.head_assets`**:

```ruby
RubyUIAdmin.configure do |config|
  config.head_assets = lambda do
    safe_join([
      stylesheet_link_tag("application", "data-turbo-track": "reload"),
      javascript_importmap_tags # or javascript_include_tag("application", type: "module")
    ])
  end
end
```

`config.head_assets` is a proc evaluated in the Rails view context, so it can call the usual asset
helpers. When it's `nil`, the layout emits no assets (the page still renders, just unstyled and
without enhancement). `config.javascript` is a convenience flag your proc can read to skip the JS
tags.

> **Turbo is on.** Navigation uses Turbo Drive (no full-page reloads), so POST→redirect responses
> use **303 See Other** and the toaster region is re-rendered each visit (it is intentionally not
> `turbo-permanent`) so flash messages always appear. Lazy tabs and the action modal load through
> **Turbo Frames**. Caveat: if your *host* app uses Turbo + importmap, the link into the engine must
> be a full page load (`data-turbo="false"` on that link) so the engine's own importmap applies.

## What it enhances

### Tabs (`rua--tabs`)

Tab groups (`tabs do … end` in a resource) render as stacked, titled cards **without JS**. The
controller reveals the tab bar, hides the redundant per-panel headings, and shows only the active
panel. Switching tabs is instant and needs no server round-trip.

#### Lazy tabs

When `config.lazy_tabs` is on, non-active tabs render only a `<turbo-frame loading="lazy" src="…">`
(a spinner until it loads). Turbo fetches the fragment URL when the tab becomes visible (the show
action returns just that tab's content wrapped in the matching `<turbo-frame id>`), and swaps it in
— no custom fetch; the `rua--tabs` controller only switches panels. Without JS the deferred tabs
show a `<noscript>` "requires JavaScript" notice. See
[Tabs & Panels › Lazy tab loading](../resources/tabs-panels.md#lazy-tab-loading).

### Action modals (`rua--dialog`)

A custom action trigger opens an inline **modal** whose body is a `<turbo-frame>` holding the
action's form (loaded lazily, so the action's fields aren't evaluated until the modal opens).
**Non-bulk** modals carry a static `src` + `loading="lazy"` (Turbo loads them when the dialog
becomes visible); **bulk** modals have no server-side `src` — `rua--dialog#open` sets it from the
currently checked rows, so reopening with a different selection refetches. The form carries
`data-turbo-frame="_top"`, so submitting breaks out into a full Turbo visit (POST→303→redirect+flash)
rather than reloading just the frame. Without JS the same trigger is a plain link to the action's
page, so actions always work. The modal closes on the ✕ button, the backdrop, the cancel link, or
the Escape key.

### Bulk selection (`rua--bulk-select`)

On index tables with bulk actions, the controller reveals the "select all" checkbox (hidden
without JS) and toggles the per-row record checkboxes; the checked ids are submitted with a bulk
action. Without JS there is no client-side selection.

### Row links (`rua--row-link`)

With `config.click_row_to_view_record`, clicking an index row (or a row in a `has_many`
association table) navigates to the record's show page — ignoring clicks on links/buttons/inputs
so row controls keep working. Without JS rows aren't clickable (the per-row show/edit links remain).

### Delete confirmation (`rua--confirm`)

The **Delete** control opens a confirmation **AlertDialog** (shared, on `<body>`) before
submitting; confirming submits the delete form. Without JS the form submits directly, so deletion
still works.

### Notifications (Toast) — `ruby-ui--toaster` / `ruby-ui--toast`

Flash messages (`notice` / `alert`, and any `succeed`/`error`/`inform`/`warn` from an action)
render through the genuine **RubyUI Toast** component (vendored under `RubyUIAdmin::UI::Toast*`).
Toasts appear **bottom-right**, with a variant-coloured left border and icon, stack, auto-dismiss,
and can be swiped or closed. Flash key → variant: `notice`/`success` → **success** (green),
`alert`/`error` → **error** (red), plus `warning`/`info`. You can also raise them from your own JS:

```js
RubyUI.toast.success("Saved")
RubyUI.toast.error("Something went wrong", { description: "Try again." })
```

Without JS, a `<noscript>` fallback shows the messages as badges so they're never lost.

### Sidebar — `ruby-ui--sidebar`

The left navigation is the genuine **RubyUI Sidebar** (`RubyUIAdmin::UI::Sidebar*`). It is **fixed
and expanded by default**; the top-bar trigger collapses it to an **icon rail** (`collapsible: :icon`)
and the choice is **persisted in a cookie** (`sidebar_state`, 7 days). Below `768px` it becomes a
**drawer** (a RubyUI Sheet). Without JS the sidebar simply renders expanded.

## Markup hooks

The controllers are driven by standard Stimulus attributes (`data-controller`,
`data-action`, `data-<id>-target`, `data-<id>-<name>-param/value`) plus a few `data-rua-*` markers
(handy if you eject/customize views):

| Hook | Purpose |
|---|---|
| `[data-controller="rua--tabs"]` | tab group; targets `tab`/`panel`/`nav`/`heading`, action `click->rua--tabs#show` |
| `[data-rua-tab="key"]` / `[data-rua-tab-panel="key"]` | button↔panel key matching |
| `<turbo-frame id="rua-tab-frame-N" loading="lazy" src="/url">` | a deferred tab panel; Turbo loads it when the tab is shown (`config.lazy_tabs`) |
| `[data-controller="rua--dialog"]` | manages action modals; trigger `click->rua--dialog#open` + `…-id-param`/`…-bulk-param`, close via `click->rua--dialog#close` |
| `[data-rua-dialog="id"]` + inner `<turbo-frame>` | the modal; the frame loads the form (`[data-rua-frame-base]` on bulk frames is the base URL the controller appends checked ids to) |
| `[data-controller="rua--bulk-select"]` | table bulk selection; target `selectAll`, action `change->rua--bulk-select#toggleAll`; `[data-rua-row-select]` marks a record checkbox |
| `[data-controller="rua--row-link"]` | clickable row; `…-url-value` + `click->rua--row-link#navigate` |
| `[data-controller="rua--confirm"]` (on `<body>`) | shared confirm AlertDialog; targets `dialog`/`title`/`message`; trigger `click->rua--confirm#request` + `…-message-param`/`…-heading-param`; `#confirm`/`#cancel` |
| `[data-controller="ruby-ui--toaster"]` / `…--toast` | the RubyUI Toast region/items |
| `[data-controller="ruby-ui--sidebar"]` + `[data-sidebar="trigger"]` | the RubyUI Sidebar (collapse + mobile drawer) |
| `[data-controller="ruby-ui--combobox"]` | the RubyUI Combobox (searchable filters and actions menu) |

> Progressive enhancement is intentional: the whole admin is usable with JavaScript disabled.
