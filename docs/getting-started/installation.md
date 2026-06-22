# Installation

> **The admin renders *your app's* RubyUI components and uses *your app's* assets.** So setup is
> mostly about pointing the admin at your existing RubyUI + Tailwind + JS bundler. If your app
> already uses RubyUI, most of this is already in place.

## 1. Add the gems

```ruby
# Gemfile
gem "ruby_ui_admin"

# Prerequisite — the UI is built from your app's RubyUI components.
gem "ruby_ui", github: "ruby-ui/ruby_ui", require: false
```

```bash
bundle install
```

`ruby_ui_admin` depends on `phlex-rails`, `tailwind_merge`, `action_policy`, `pagy` and
`turbo-rails` (Bundler installs them automatically). It also expects a **Tailwind build** and a
**JavaScript bundler or importmap** in your app — the same setup RubyUI itself needs.

## 2. Install RubyUI and generate its components

If your app doesn't already use RubyUI, install it and generate the components the admin uses —
at minimum: `card`, `badge`, `button`, `link`, `typography` (provides `InlineLink`), `checkbox`,
`input`, `textarea`, `table`, `sidebar`, `sheet`, `combobox`.

> **Run `phlex:install` first.** RubyUI's installer only runs `phlex:install` (which creates
> `app/components/base.rb`) when `phlex-rails` isn't already in the bundle. Because `ruby_ui_admin`
> depends on `phlex-rails`, it skips that step and then aborts when `app/components/base.rb` is
> missing — leaving `RubyUI::Base` ungenerated (and `tw-animate-css` uninstalled), which breaks boot
> when you generate components. Running `phlex:install` yourself first avoids the whole chain.

```bash
bin/rails generate phlex:install      # creates app/components/base.rb (see note above)
bin/rails generate ruby_ui:install
```

> `ruby_ui:install` **overwrites** your Tailwind entry CSS behind an interactive prompt — run it on
> its own (not pasted inside a larger block) and answer `Y`, then re-add your customizations (e.g. the
> `@source` line below). On **Tailwind v4** (tailwindcss-rails 3+, the current default) that file is
> `app/assets/tailwind/application.css`; older setups use
> `app/assets/stylesheets/application.tailwind.css`. It also installs `tw-animate-css`;
> if a later CSS build errors on it, add it manually (`yarn add tw-animate-css` / importmap pin) and
> ensure your CSS imports it.

Then generate the components the admin renders. The gem knows which ones it needs, so let it drive
RubyUI's generator for you (safe to re-run — existing components are skipped):

```bash
bin/rails generate ruby_ui_admin:components
```

<details><summary>What it runs (and why not one command)</summary>

RubyUI's generator takes **one component per command**, and **`InlineLink` is part of the
`Typography` group** (a bare `ruby_ui:component InlineLink` fails silently and the admin's index
later breaks, since it renders `RubyUI::InlineLink`). The generator loops over exactly the set the
admin uses:

```bash
for c in Card Badge Button Checkbox Combobox Typography Link Input Textarea Table Sidebar Sheet; do
  bin/rails generate ruby_ui:component $c --skip
done
# (or `bin/rails generate ruby_ui:component all` to generate everything)
```
</details>

This drops the components into `app/components/ruby_ui/*` (as `RubyUI::*`) and copies RubyUI's
Stimulus controllers into `app/javascript/controllers/ruby_ui/*`. **You own these files.**

## 3. Wire the assets

The admin doesn't ship CSS/JS — it reuses yours.

**a. Tailwind** — your build must generate the utility classes the admin's views use. Rather than
`@source`-ing the gem's `.rb` files (their absolute path differs between dev/CI/deploy, so it can't
be committed), extract the class inventory into your **own** app tree and source that:

```bash
bin/rails ruby_ui_admin:tailwind_source
```

It writes `app/assets/tailwind/ruby_ui_admin_classes.html` (the classes scanned from the admin's
views) and prints the line to add to your Tailwind entry CSS:

```css
/* Tailwind v4: app/assets/tailwind/application.css  (v3: app/assets/stylesheets/application.tailwind.css) */
@source "./ruby_ui_admin_classes.html";
```

**Commit the generated file** — that stable, relative path works in every environment. **Re-run the
task after upgrading the gem** so new classes are picked up. Also make sure your RubyUI theme defines
the `success` / `warning` design tokens (the admin's badges/toasts use them — RubyUI ships them).

**b. Stimulus controllers** — the admin needs two sets registered in your Stimulus app:

1. **The admin's own `rua--*` controllers** (`tabs`, `dialog`, `bulk-select`, `row-link`,
   `confirm`).
2. **`ruby-ui--toaster` + `ruby-ui--toast`** — the admin renders RubyUI's **Toast** for flash
   messages **even if your app doesn't use RubyUI Toast**, so you likely won't have these from
   step 2. (The other `ruby-ui--*` it uses — combobox, sheet, sidebar — *do* come from your own
   RubyUI in step 2.)

The gem ships both sets, flat, under `public/ruby-ui-admin-assets/controllers/` (the toaster
controller is patched for server-rendered flash toasts — use the gem's copy), alongside an
`index.js` that imports and **registers each one under the identifier its markup expects**. Run the
generator — it does the right thing for your JS setup and prints the **one line** you add:

```bash
bin/rails generate ruby_ui_admin:assets
```

**Bundler (esbuild / jsbundling / vite).** It copies the directory to `app/javascript/ruby_ui_admin/`
(a sibling of `controllers/`, so `eagerLoadControllersFrom("controllers", …)` doesn't re-register
them under bogus names). The bundler inlines `index.js`'s relative imports, so:

```js
// app/javascript/application.js
import "./ruby_ui_admin"
```

**Importmap + Propshaft.** It does **not** copy — copied files get content-digested, and `index.js`'s
relative `./x.js` imports would then resolve to undigested URLs Propshaft won't serve (404). Instead
it pins the copy the engine already serves **undigested** (via Rack::Static), where relative imports
work and `@hotwired/stimulus`/`@hotwired/turbo` resolve through your own import map:

```ruby
# config/importmap.rb
pin "ruby_ui_admin", to: "/ruby-ui-admin-assets/controllers/index.js"
# then in app/javascript/application.js:  import "ruby_ui_admin"
```

Either way that single import registers every controller (`rua--*`, `ruby-ui--toaster`/`ruby-ui--toast`,
plus combobox/sheet/sidebar) — **no `stimulus:manifest:update`**. Rebuild your JS (bundler) afterwards.
Don't hand-translate the files into `controllers/rua/…` folders — the manifest would derive the wrong
identifiers.

> If flash toasts don't appear after an action, it's almost always the `ruby-ui--toaster` /
> `ruby-ui--toast` controllers missing from your bundle — re-run the generator and re-add the import.

RubyUI's combobox/popover controllers depend on `@floating-ui/dom` — already present if you use
RubyUI's combobox.

## 4. Mount the engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount_ruby_ui_admin at: "/admin"
end
```

Draws a RESTful route set for every resource you define (`resources_posts_path`,
`new_resources_post_path`, `edit_resources_post_path`, …).

## 5. Configure

```ruby
# config/initializers/ruby_ui_admin.rb
RubyUIAdmin.configure do |config|
  config.app_name = "My Admin"
  config.per_page = 24

  # Resolve the signed-in admin (the block runs in the controller context).
  config.current_user_method { current_user }

  # Optional gate run before every admin request.
  config.authenticate_with { redirect_to main_app.login_path unless current_user&.admin? }

  config.authorization_client  = :action_policy
  config.explicit_authorization = false

  # REQUIRED — the admin layout's <head>. Point it at your app's compiled CSS + JS (the same
  # tags your application layout uses). Evaluated in the Rails view context.
  config.head_assets = lambda do
    safe_join([
      stylesheet_link_tag("application", "data-turbo-track": "reload"),
      # importmap host: use `javascript_importmap_tags` instead of the line below.
      javascript_include_tag("application", "data-turbo-track": "reload", defer: true)
    ])
  end
end
```

> Without `config.head_assets`, the admin pages render with **no styling and no JavaScript**.

## 6. Define a resource

Create `app/ruby_ui_admin/resources/post.rb` (see [Resources → Overview](../resources/overview.md)).

---

`bin/rails generate ruby_ui_admin:install` scaffolds steps **4–5** (the initializer + mount), and
`ruby_ui_admin:assets` copies the Stimulus controllers from step **3**. The rest of steps **2–3**
(RubyUI components + Tailwind `@source`) depend on your app's bundler/Tailwind setup and are
manual — see [Theming with RubyUI](../customization/theming-rubyui.md) and
[JavaScript](../customization/javascript.md).
