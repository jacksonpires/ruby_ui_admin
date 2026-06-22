# Associations

Declare associations as fields. They render as links to the related records.

```ruby
def fields
  field :user, as: :belongs_to                  # parent record
  field :profile, as: :has_one
  field :comments, as: :has_many
  field :tags, as: :has_and_belongs_to_many
end
```

## Display

| Type | Renders |
|---|---|
| `belongs_to` | a link to the parent record's show page; an editable select on forms |
| `has_one` | a link to the associated record's show page |
| `has_many` / `has_and_belongs_to_many` | a full-width **table** of the related records (capped, with “+N more”) |

Links resolve through the related model's registered resource (so a `Comment` row links to
`/admin/comments/:id`). If no resource is registered for the related model, the label is shown
without a link.

### Collection tables (`has_many` / `has_and_belongs_to_many`)

Collection associations render as a RubyUI table whose **columns are the related resource's
index fields** (so a `comments` association shows the same columns as the Comments index), with
each row linking to the record's show page. On the show view the table spans the full width,
with the association name and description above it.

Limit and order the columns with the `fields:` option — a list of field ids from the related
resource:

```ruby
field :suppliers, as: :has_many, fields: %i[name identifier state buyer]
```

Without `fields:`, all of the related resource's index columns are shown. If the related model
has no registered resource, the table falls back to a single column of record links.

By default `has_one`/`has_many`/`has_and_belongs_to_many` appear **only on the show view**
(they're hidden on index and forms); `belongs_to` appears everywhere. Override with
`only_on:` / `hide_on:` like any field.

Give related models a `to_label` (or `name`/`title`) for friendly link text; otherwise a
`"<Model> #<id>"` label is used.

## Authorization

Associations are gated like any field — define `view_<association>?` (or per-view
`show_<association>?`) on the resource policy:

```ruby
class PostPolicy < RubyUIAdmin::BasePolicy
  def view_comments? = user.admin?   # hide the comments association from non-admins
end
```

See [Field-level authorization](../authorization/field-authorization.md) for the full
resolution rules. As with any field, an undefined rule means the association stays visible.

> Inline association **management** (attach/detach controls and pagination within the table)
> is planned for a later phase. Today collection associations are read-only tables on the show
> view (capped, with a “+N more” note).
