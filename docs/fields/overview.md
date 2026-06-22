# Fields — Overview

Declare fields inside a resource's `def fields` with `field :name, as: :type, **options`.

## Available field types

| `as:` | Renders | Notes |
|---|---|---|
| `:id` | record id | links to the record by default; hidden on forms |
| `:text` | single-line text | `as_html: true` to render raw HTML |
| `:textarea` | multi-line text | `rows:` |
| `:number` | numeric input | `min:`, `max:`, `step:` |
| `:boolean` | Yes/No badge / checkbox | |
| `:date` | date | `format:` (strftime) |
| `:date_time` | date + time | `format:` (strftime) |
| `:select` | dropdown | `options:` (Hash/Array/lambda), `include_blank:` |
| `:url` | external link | `text:`, `target:` |
| `:hidden` | hidden input | forms only |
| `:password` | password input | never displays/overwrites with a blank value |
| `:badge` | colored badge | `options: { value => :variant }` |
| `:status` | status badge | `options: { success: [...], warning: [...], danger: [...] }` |
| `:code` | preformatted code | `language:`; hidden on index |
| `:key_value` | key/value table; JSON textarea | for Hash columns |
| `:boolean_group` | group of checkboxes; value is a `{ key => bool }` Hash | `options: { key => label }` (Hash/Array/lambda); hidden on index by default |
| `:belongs_to` | linked parent record / select | |
| `:has_one` | linked child record | show view only |
| `:has_many` | list of linked records | show view only |
| `:has_and_belongs_to_many` | list of linked records | show view only |
| `:record_link` | link to a record via another resource | `use_resource:` |
| `:file` | single ActiveStorage attachment | `accept:`, `preview_size:` |
| `:files` | multiple ActiveStorage attachments | `accept:`, `preview_size:` |

> **`:file` / `:files`** map to `has_one_attached` / `has_many_attached` (the field id is the
> attachment name). Forms render a file input (multipart, honoring `accept:`) and persist the
> upload, skipping a blank input so an existing attachment isn't wiped. A `:file` edit form also
> shows the current filename and a **"remove" checkbox** that purges the attachment on save. For
> `:files`, the edit form lists each existing attachment with its own remove checkbox, and new
> uploads are **appended** (they don't replace the existing set). On the show view, images render
> as a thumbnail and other files as a **download link** with the filename (resolved through your
> app's ActiveStorage routes). Image thumbnails are capped at 64×64 by default; set
> **`preview_size:`** to change the max display size — an Integer (square, `preview_size: 100`) or
> `[width, height]` (`preview_size: [120, 80]`); large images scale down to fit, preserving aspect.
> Hidden on the index by default.

## Common options

- `name:` — override the displayed label
- `only_on:` / `hide_on:` — restrict to views (`:index, :show, :new, :edit`; `:forms` = new+edit;
  `:display` = index+show)
- `link_to_record:` — link the value to the record's show page
- `sortable:` — `true` to sort by the column, or a lambda for custom sorting. The lambda is
  evaluated with `query`, `direction` (`:asc`/`:desc`) and `resource` available as readers, and must
  return the reordered relation: `sortable: -> { query.reorder(author: {name: direction}) }`
- `filterable:` — mark the field as filterable (used by [filters](../filters/overview.md))
- `required:`, `readonly:`
- `default:` — prefills the field on **new** records. A literal (`default: "draft"`) or a lambda
  evaluated with `record`, `resource` and `current_user` (`default: -> { current_user&.email }`).
  Submitted values always override the default.
- `help:` — small text below the input on forms; `placeholder:`
- `description:` — a tooltip (`title=`) on the field label (form + show)
- `visible:` — a literal or lambda (with `view`/`record`/`resource`/`current_user`) hiding the field
  when it returns false, e.g. `visible: -> { current_user.admin? }`. `view` is a small object that
  responds both to `view == :show` and to predicates `view.show?` / `view.index?` / `view.new?` /
  `view.edit?` (plus `view.form?` and `view.display?`)
- `format_using:` — a lambda `->(value:, record:) { ... }` to format the displayed value
- `options:` (select) — a Hash (`{value => label}`), Array, or a lambda. The lambda can use
  `record`/`resource` plus `params`/`view` (e.g. options that depend on a request param)
- `enum:` (select) — derive options from an ActiveRecord enum: `enum: Post.statuses` or `enum: true`
- `display_with_value:` (select) — option labels become `"Label (value)"`
- `language:` (code) — sets `language-<lang>` on the `<code>` element for syntax highlighters
- association fields (`has_many`/`has_one`/`belongs_to`): `use_resource:` (link through a specific
  resource), `scope:` (Symbol/lambda narrowing the relation), `for_attribute:` (read a differently-named
  association)
- a block — compute the value: `field(:full_name) { record.first + record.last }`. The block has
  `record`, `resource` and `current_user` available, plus view/url helpers (`link_to`, `main_app`,
  `ruby_ui_admin`, `*_path`). If it returns HTML-safe output (e.g. from `link_to`) it renders raw:

  ```ruby
  field :author, as: :text do
    link_to(record.user.name, ruby_ui_admin.resources_users_path) if record.user
  end
  ```
- `as_html:` — on a `:text` field, render the (plain string) value as raw HTML instead of escaping it

## Auto-discovery

Instead of listing every column, derive fields from the schema:

```ruby
def fields
  discover_columns(except: %i[created_at updated_at])
  discover_associations(only: %i[user comments])
end
```
