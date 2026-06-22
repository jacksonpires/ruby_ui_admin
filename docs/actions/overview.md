# Actions — Overview

Custom actions run code against one or more records (or standalone). Define them in
`app/ruby_ui_admin/actions` under `RubyUIAdmin::Actions`, then attach them to a resource.

```ruby
module RubyUIAdmin
  module Actions
    class PublishPosts < RubyUIAdmin::BaseAction
      self.name = "Publish"
      self.message = "Publish the selected posts?"
      self.confirm_button_label = "Publish"

      def handle(query:, fields:, current_user:, **)
        query.each { |post| post.update!(published: true) }
        succeed "Published #{query.size} post(s)."
      end
    end
  end
end
```

Attach to a resource:

```ruby
def actions
  action RubyUIAdmin::Actions::PublishPosts
  action RubyUIAdmin::Actions::ImportPosts, arguments: {source: "csv"}
end
```

## Class options

| Option | Purpose |
|---|---|
| `self.name =` | Button / page label |
| `self.message =` | Text (HTML allowed) shown on the confirmation page. Accepts a lambda evaluated with `records`/`record`/`resource`/`current_user`, e.g. `-> { "Publish #{records.size} posts?" }` |
| `self.confirm_button_label =` / `self.cancel_button_label =` | Button labels |
| `self.standalone =` | `true` for actions that need no record selection (shown on the index) |
| `self.no_confirmation =` | Skip the confirmation page (planned) |
| `self.visible =` | Lambda controlling where the action appears. `view` responds to both `view == :show` and predicates `view.show?` / `view.index?` (also `new?`/`edit?`/`form?`/`display?`), plus `resource`/`record` |

## Form fields

Declare inputs the same way as resource fields; submitted values arrive in `fields`, a
hash with **indifferent access** (read by symbol or string). A `file`/`files` field turns the
action form into a multipart upload automatically:

```ruby
def fields
  field :reason, as: :text, required: true
  field :notify, as: :boolean
  field :csv_file, as: :file
end

def handle(args)
  upload = args[:fields][:csv_file]   # symbol or string both work
  # ...
end
```

## The `handle` method

Two signatures are supported:

```ruby
def handle(query:, fields:, current_user:, resource:, **); end  # keyword style
def handle(args); end   # args[:records], args[:fields], args[:current_user], args[:resource]
```

`query` / `args[:records]` is the array of selected records (empty for standalone actions).

## Response helpers

Call these inside `handle`:

- `succeed(text)`, `error(text)`, `inform(text)`, `warn(text)` — flash messages
- `redirect_to(path)` — a String or a lambda (evaluated in the controller, so engine route
  helpers like `resources_posts_path` are available)

  Route helpers are also available **directly inside `handle`**: bare `*_path`/`*_url` calls
  resolve against the engine routes first, then the host app. Use `main_app.*` for host routes
  and `ruby_ui_admin.*` for engine routes explicitly:

  ```ruby
  redirect_to resources_posts_path                 # engine route, bare
  succeed main_app.user_url(record)                 # host route
  ```
- `reload` — re-render the originating page (default)
- `download(content, filename)` — send a file
- `keep_modal_open` — (planned, for the modal UI)

## Authorization

Actions are gated by the resource policy's `act_on?` rule. If it returns false the action
is hidden and running it is forbidden.

Action buttons open an inline **modal** with the form (falling back to a dedicated
confirmation page when JavaScript is disabled — see [JavaScript](../customization/javascript.md)).

## Bulk actions

Non-`standalone` actions become **bulk actions** on the index: a checkbox column appears
(with a “select all”), and each action runs against the checked rows.

- **With JS**: check rows, click the action — the selected ids are injected into the action
  modal, which submits them to the action.
- **Without JS**: the checkbox selection is submitted to the action's confirmation page (via
  the HTML `form` attribute, so no nested forms), where you confirm and run.

`standalone` actions ignore selection and run on their own; record actions also remain
available on each record's show view.
