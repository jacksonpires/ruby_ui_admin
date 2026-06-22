# Configuration

RubyUI Admin is configured through an initializer created by `rails g ruby_ui_admin:install`:

```ruby
# config/initializers/ruby_ui_admin.rb
RubyUIAdmin.configure do |config|
  config.app_name = "My Admin"
  config.root_path = "/admin"
  config.per_page = 24

  config.current_user_method { current_user }

  config.authorization_client = :action_policy
  config.explicit_authorization = false
end
```

The block runs once at boot. Read values anywhere at runtime via `RubyUIAdmin.configuration`
(aliased as `RubyUIAdmin.config`), e.g. `RubyUIAdmin.configuration.app_name`.

## Active options

| Option | Default | Description |
|---|---|---|
| `app_name` | `"RubyUI Admin"` | Shown in the sidebar header and page `<title>`s. |
| `root_path` | `"/admin"` | Default mount path used by `mount_ruby_ui_admin`. Keep it in sync with the `at:` you pass when mounting. |
| `home_path` | `nil` | Where the engine root (`/admin`) redirects. When `nil`, it redirects to the first resource's index. Set an absolute path, e.g. `"/admin/dashboards/overview"`. |
| `per_page` | `24` | Records per page on index views. |
| `timezone` | `"UTC"` | Timezone applied to each admin request (`Time.zone`); `date_time` fields render in it. |
| `locale` | `nil` | When set, wraps each admin request in `I18n.with_locale`. |
| `current_user_method` | `nil` | Block that resolves the signed-in admin. See [authentication](authentication.md). |
| `true_user_method` | `nil` | Block resolving the real (non-impersonated) user; defaults to `current_user`. Policies can read it via `true_user`. |
| `click_row_to_view_record` | `false` | When `true`, clicking an index row opens the record's show page (needs JS). |
| `lazy_tabs` | `false` | When `true`, non-active show tabs load their content on demand (fetched when first opened, with a spinner) instead of all rendering up front — useful for show pages with heavy association tabs. Needs JS; without it the active tab still renders and deferred tabs show a "requires JavaScript" notice. See [Tabs & Panels](../resources/tabs-panels.md#lazy-tab-loading). |
| `pagination` | `{}` | Global pagination options (or a proc returning them). Set `{ type: :countless }` to paginate without a `COUNT` query everywhere; per-resource `self.countless` can also opt in individually. |
| `authenticate_with` | `nil` | Block run before every admin request (authentication gate). See [authentication](authentication.md). |
| `authorization_client` | `:action_policy` | Authorization backend (adapter): `:action_policy` (default), `:pundit`, `:cancancan`, or a custom adapter class (subclass of `RubyUIAdmin::Authorization::Adapter`). `:pundit`/`:cancancan` require the matching gem. Set to `nil` to disable authorization entirely. ⚠️ `:cancancan` is partial: no field-level rules and `explicit_authorization` has no effect (grant via your `Ability`). |
| `cancancan_ability_class` | `nil` | Ability class (or its name) for the `:cancancan` adapter; defaults to the conventional `Ability`. Ignored by other adapters. |
| `explicit_authorization` | `false` | When `true`, rules a policy doesn't define (and missing policies) are **denied**. When `false`, they're **allowed**. See [authorization](../authorization/action-policy.md). |
| `resources` | `nil` | `nil` = auto-discover resources under `app/ruby_ui_admin/resources`. Or pass an explicit array of class names. |
| `model_resource_mapping` | `{}` | Map a model to a resource when the names don't match, e.g. `{ "Buyer" => "RubyUIAdmin::Resources::Customer" }`. |
| `head_assets` | `nil` | Proc (evaluated in the Rails view context) returning the `<head>` asset markup — your app's stylesheet + JS tags. The admin renders your RubyUI components, so the host owns the CSS/JS. When `nil`, the layout emits no assets. See [JavaScript](../customization/javascript.md) and [Theming](../customization/theming-rubyui.md). |
| `javascript` | `true` | Convenience flag your `head_assets` proc can read to include/skip the JS tags. The admin works without JS (progressive enhancement). |
| `sign_out_path_name` | `nil` | Name of a host route helper (resolved via `main_app`) for signing out. When set, a sign-out item renders at the bottom of the sidebar, e.g. `:destroy_user_session_path` (Devise). |
| `sign_out_method` | `:delete` | HTTP method for the sign-out item. |
| `docs_enabled` | `:local` | Mounts the in-app docs browser at `<mount>/docs`. `:local` = dev/test only (open); `true` = all environments incl. production (behind auth); `false` = never; or a callable. See [In-app docs browser](#in-app-docs-browser). |

### Authentication blocks

`current_user_method` and `authenticate_with` are evaluated with `instance_exec` **in the
admin controller's context**, so they can call your host app's helpers (`current_user`,
`redirect_to`, `main_app.*`). Both forms work:

```ruby
config.current_user_method { current_user }                   # no args
config.current_user_method { |context| context.current_user } # receives the controller

config.authenticate_with { redirect_to main_app.login_path unless current_user&.admin? }
```

If `current_user_method` is **not** set, the engine falls back to `request.env["warden"]&.user`
(works out of the box for Devise/Warden hosts). The admin controller inherits from
`ActionController::Base` (not your host `ApplicationController`), so it doesn't have Devise's
`current_user` helper — configure the block (or rely on the Warden fallback).

See [Authentication](authentication.md) for the full flow.

## Reserved options (no effect yet)

These exist for API parity and forward compatibility but are **not wired up yet** — setting
them has no effect today. They are safe to leave in a config (they won't error).

| Option | Intended purpose |
|---|---|
| `per_page_steps` | Choices for a future per-page selector. |
| `raise_error_on_missing_policy` | Alternative to `explicit_authorization` for missing policies. |
| `profile_menu` | Block to build a profile/account menu. |

## Curated navigation (`main_menu`)

By default the sidebar auto-lists every dashboard and every resource with
`visible_on_sidebar` (the default). Set `config.main_menu` to a block to curate it instead —
group items into sections, rename them, add arbitrary links, or expand everything:

```ruby
RubyUIAdmin.configure do |config|
  config.main_menu = -> do
    section "Content", icon: "table" do
      resource :post, label: "Articles"   # rename a resource link
      resource :comment
      link "Docs", "https://example.com/docs"
    end

    section "People" do
      all_resources(except: [:posts, :comments])  # everything else
    end

    section "Dashboards" do
      all_dashboards
    end
  end
end
```

DSL available inside the block:

| Method | Adds |
|---|---|
| `section(label, icon: nil) { ... }` | a titled group (alias: `group`). `icon:` accepts a raw SVG/HTML string, rendered before the label |
| `resource(name, label: nil)` | a link to a resource's index (alias: `resources`) |
| `link(label, path)` | an arbitrary link (alias: `link_to`) |
| `dashboard(id, label: nil)` | a link to a dashboard |
| `all_resources(except: [])` | one item per navigable resource |
| `all_dashboards(except: [])` | one item per dashboard |

`current_user` and `params` are available inside the block (e.g. to vary the menu per user).
When `main_menu` is unset, the auto navigation is used.

## In-app docs browser

The admin can serve this documentation, rendered as HTML, at `<mount>/docs` (e.g. `/admin/docs`) —
a convenience for reading the gem's docs without leaving the app. Availability is controlled by
`config.docs_enabled`:

| Value | Behaviour |
|---|---|
| `:local` (default) | Mounted in development/test only; **open** (no authentication). |
| `true` | Mounted in **all** environments, including production. |
| `false` | Never mounted. |
| a callable | Evaluated at boot; truthy enables it (e.g. `-> { ENV["DOCS"] == "1" }`). |

```ruby
config.docs_enabled = true   # expose /admin/docs in production too
```

**Authentication.** In local environments the viewer is open for convenience. In any **other**
environment (production), it runs behind the same `authenticate_with` gate as the rest of the
admin — so enabling it in production does not expose your docs publicly.

**Markdown renderer.** It renders Markdown with [kramdown](https://kramdown.gettalong.org), required
lazily. Add the gems to whichever Bundler group the target environment loads — `:development` for
the default `:local` setting, or a group present in production if you set `docs_enabled = true`:

```ruby
# Gemfile — for the default (:local) setting:
group :development do
  gem "kramdown"
  gem "kramdown-parser-gfm"
end

# ...or, if you enable docs in production, put them where production loads them:
gem "kramdown"
gem "kramdown-parser-gfm"
```

If the gems are missing, the page renders a short notice telling you to add them. Otherwise there's
nothing else to configure — visit `<mount>/docs` and use the sidebar to browse.

> The route is mounted at **boot** based on `docs_enabled?`, so changing the value needs a restart
> (or `bin/rails restart`) to take effect.

## Reading configuration at runtime

```ruby
RubyUIAdmin.configuration.app_name      # => "My Admin"
RubyUIAdmin.config.per_page             # => 24  (config is an alias)
RubyUIAdmin.configuration.authorization_enabled?  # => true unless authorization_client is nil
```

## See also

- [Authentication](authentication.md)
- [Authorization with action_policy](../authorization/action-policy.md)
