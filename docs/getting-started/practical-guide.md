# Practical guide: a working admin from scratch

This is a copy‑paste walkthrough that takes a brand‑new Rails app to a functional admin with
two associated models, configured resources, and a couple of filters. It uses a small
**Bookshelf** domain: an `Author` that `has_many :books`.

The demo skips authentication and authorization so it "just works" — see the
[Authentication](authentication.md) and [Authorization](../authorization/action-policy.md)
docs to wire those up for real.

---

## 1. Create the Rails app

The admin renders RubyUI (Phlex) components styled with Tailwind, so start the app with a
Tailwind build and a JS bundler:

```bash
rails new bookshelf --css tailwind --javascript esbuild
cd bookshelf
```

## 2. Add the gem

```ruby
# Gemfile
gem "ruby_ui_admin"

# The admin's UI is built from your app's RubyUI components.
gem "ruby_ui", require: false

# Optional: renders the gem's docs at /admin/docs in development (see step 9).
group :development do
  gem "kramdown"
  gem "kramdown-parser-gfm"
end
```

> Until it's published to RubyGems, point at a local checkout or Git instead, e.g.
> `gem "ruby_ui_admin", path: "../ruby_ui_admin"` or `gem "ruby_ui_admin", github: "you/ruby_ui_admin"`.

```bash
bundle install
```

Generate RubyUI and the components the admin uses (they land in `app/components/ruby_ui/*` and
their Stimulus controllers in `app/javascript/controllers/ruby_ui/*` — you own them).

> **Run `phlex:install` first.** RubyUI's installer only runs `phlex:install` (which creates
> `app/components/base.rb`) when `phlex-rails` isn't already in the bundle. Because `ruby_ui_admin`
> depends on `phlex-rails`, the installer skips that step, then aborts when it can't find
> `app/components/base.rb` — leaving `RubyUI::Base` ungenerated and breaking boot. Running
> `phlex:install` yourself first sidesteps it.

```bash
bin/rails generate phlex:install      # creates app/components/base.rb (see note above)
bin/rails generate ruby_ui:install
```

> RubyUI's `install` overwrites your Tailwind entry CSS with an **interactive prompt** — run it on
> its own (don't paste a whole block at once) and answer `Y`, then re-add any customizations. On
> Tailwind v4 (the current default) that file is `app/assets/tailwind/application.css`; older setups
> use `app/assets/stylesheets/application.tailwind.css`. If the CSS build later errors on
> `tw-animate-css`, install it (`yarn add tw-animate-css` or pin it for importmap) and make sure your
> CSS imports it — RubyUI's installer adds this for you when it completes successfully.

Then generate the components the admin uses. The gem knows the set, so let it drive RubyUI's
generator (safe to re-run — existing components are skipped):

```bash
bin/rails generate ruby_ui_admin:components
```

> Under the hood it loops over the set the admin renders, one per command (RubyUI's generator takes
> one at a time), using the `Typography` group for `InlineLink` — a bare `ruby_ui:component
> InlineLink` fails silently and the index would break later. You can also run
> `bin/rails generate ruby_ui:component all` to generate everything.

## 3. Generate two scaffolds with an association

`author:references` makes `Book` belong to an `Author` (adds the foreign key and the
`belongs_to :author`).

```bash
bin/rails generate scaffold Author name:string email:string
bin/rails generate scaffold Book title:string published:boolean author:references
bin/rails db:migrate
```

## 4. Complete the association

The scaffold added `belongs_to :author` to `Book`. Add the other side to `Author`:

```ruby
# app/models/author.rb
class Author < ApplicationRecord
  has_many :books, dependent: :destroy

  def to_label = name   # used as the record's display label in the admin
end
```

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  belongs_to :author

  def to_label = title
end
```

## 5. Mount and configure the admin

Run the install generator — it creates the initializer and mounts the engine at `/admin`:

```bash
bin/rails generate ruby_ui_admin:install
```

Then replace the generated initializer with this demo configuration (no auth, no policies):

```ruby
# config/initializers/ruby_ui_admin.rb
RubyUIAdmin.configure do |config|
  config.app_name  = "Bookshelf Admin"
  config.root_path = "/admin"
  config.per_page  = 20

  # This demo has no authentication. Returning nil and disabling authorization lets the
  # admin run without a current_user or any policies. In a real app, wire current_user_method
  # to your auth (e.g. Devise) and set authorization_client = :action_policy + add policies.
  config.current_user_method { nil }
  config.authorization_client = nil

  # REQUIRED — point the admin's <head> at your app's compiled CSS + JS (esbuild + Tailwind here).
  config.head_assets = lambda do
    safe_join([
      stylesheet_link_tag("application", "data-turbo-track": "reload"),
      javascript_include_tag("application", "data-turbo-track": "reload", defer: true)
    ])
  end
end
```

Two more bits of wiring so the admin is styled and interactive (see
[Installation › Wire the assets](installation.md#3-wire-the-assets)):

- **Tailwind** — extract the admin's class inventory into your app and source it (the gem path
  varies per environment, so don't hardcode it). Commit the generated file; re-run on gem upgrade:
  ```bash
  bin/rails ruby_ui_admin:tailwind_source   # writes app/assets/tailwind/ruby_ui_admin_classes.html
  ```
  ```css
  /* Tailwind v4: app/assets/tailwind/application.css (v3: app/assets/stylesheets/application.tailwind.css) */
  @source "./ruby_ui_admin_classes.html";
  ```
- **Stimulus** — copy the admin's controllers in with the generator, then add the one import it
  prints to `app/javascript/application.js` (for esbuild here, that's `import "./ruby_ui_admin"`):
  ```bash
  bin/rails generate ruby_ui_admin:assets
  ```
  It brings the admin's own `rua--*` controllers **and** `ruby-ui--toaster`/`ruby-ui--toast` (the
  admin uses RubyUI Toast for flash even though the component list above doesn't include it), all
  registered under the right identifiers — no `stimulus:manifest:update` needed. Rebuild afterwards.
  (On **Importmap + Propshaft** the generator pins the engine-served entrypoint instead of copying —
  see [Installation › Wire the assets](installation.md#3-wire-the-assets).)

The generator also added this line to your routes (mount it manually if you skipped the
generator):

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount_ruby_ui_admin at: "/admin"

  # ...your scaffolded routes (resources :authors, :books) stay as they are
end
```

## 6. Define the resources

Resources live in `app/ruby_ui_admin/resources/` and are auto‑discovered — no registration
needed. The class name maps to the model (`Author` → `Author`).

```ruby
# app/ruby_ui_admin/resources/author.rb
module RubyUIAdmin
  module Resources
    class Author < RubyUIAdmin::BaseResource
      self.title = :name          # display label for an Author record

      def fields
        field :id,    as: :id
        field :name,  as: :text, link_to_record: true, sortable: true
        field :email, as: :text
        field :books, as: :has_many   # listed on the Author's show page
      end
    end
  end
end
```

```ruby
# app/ruby_ui_admin/resources/book.rb
module RubyUIAdmin
  module Resources
    class Book < RubyUIAdmin::BaseResource
      self.title    = :title
      self.includes = [:author]   # eager-load to avoid N+1 on the index

      def filters
        filter RubyUIAdmin::Filters::PublishedFilter
        filter RubyUIAdmin::Filters::AuthorFilter
      end

      def fields
        field :title,      as: :text, link_to_record: true, sortable: true
        field :published,  as: :boolean
        field :author,     as: :belongs_to            # dropdown on forms, link on show/index
        field :created_at, as: :date_time, only_on: %i[index show]
      end
    end
  end
end
```

## 7. Add a couple of filters

Filters live in `app/ruby_ui_admin/filters/` and render above the index table.

```ruby
# app/ruby_ui_admin/filters/published_filter.rb
module RubyUIAdmin
  module Filters
    class PublishedFilter < RubyUIAdmin::Filters::BooleanFilter
      self.name = "Published"

      def apply(_request, query, value)
        query.where(published: value == "true")
      end
    end
  end
end
```

```ruby
# app/ruby_ui_admin/filters/author_filter.rb
module RubyUIAdmin
  module Filters
    class AuthorFilter < RubyUIAdmin::Filters::SelectFilter
      self.name = "Author"

      # options is { value => label }.
      def options
        ::Author.order(:name).pluck(:id, :name).to_h
      end

      def apply(_request, query, value)
        query.where(author_id: value)
      end
    end
  end
end
```

## 8. Add some data (optional)

So the admin isn't empty:

```ruby
# db/seeds.rb
rowling = Author.create!(name: "J. K. Rowling", email: "jk@example.com")
tolkien = Author.create!(name: "J. R. R. Tolkien", email: "jrr@example.com")

rowling.books.create!(title: "Harry Potter", published: true)
tolkien.books.create!(title: "The Hobbit", published: true)
tolkien.books.create!(title: "Unfinished Tales", published: false)
```

```bash
bin/rails db:seed
```

## 9. Run it

Use `bin/dev` (not `bin/rails server`) so the esbuild + Tailwind watchers build your assets:

```bash
bin/dev
```

Open <http://localhost:3000/admin>. You'll get a styled admin with
**Authors** and **Books** in the sidebar. On the Books index you'll see the **Published** and
**Author** filters; opening a Book shows its author as a link, and an Author shows its books.

> **Read the docs inside the app.** With the `kramdown` gems from step 2 installed, the admin serves
> this documentation at <http://localhost:3000/admin/docs> (development only, by default). Without
> those gems the page shows a notice telling you to add them. See
> [Configuration › In-app docs browser](configuration.md#in-app-docs-browser).

---

## Where to go next

- Group fields with [tabs & panels](../resources/tabs-panels.md), add [scopes](../resources/scopes.md)
  and [index customization](../resources/index-customization.md).
- Add [custom actions](../actions/overview.md) (e.g. "Publish selected books").
- Wire real [authentication](authentication.md) and [authorization](../authorization/action-policy.md)
  (set `authorization_client = :action_policy` and add policies).
- Browse the full [field catalog](../fields/overview.md) and [filter types](../filters/overview.md).
