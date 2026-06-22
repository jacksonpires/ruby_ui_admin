# Tabs & Panels

Group fields on the show and form views with `panel`, `tabs` and `tab`.

```ruby
def fields
  field :id, as: :id

  panel "Basic info" do
    field :title, as: :text
    field :status, as: :badge, options: {"draft" => :warning, "published" => :success}
  end

  tabs do
    tab "Content", description: "The main content" do   # description shown in the panel
      field :body, as: :textarea
      field :metadata, as: :key_value
    end

    tab "Relations" do
      field :user, as: :belongs_to
      field :comments, as: :has_many
    end
  end
end
```

## Behaviour

- **`panel(name = nil)`** — renders its fields inside a titled card. The name can also be
  passed as a keyword (`panel name: "Basic info"`); both forms are equivalent.
- **`tabs`** — declares a group of tabs; only `tab` calls belong directly inside it.
- **`tab(name, description: nil)`** — a named section inside `tabs`; can contain fields and
  panels. A bare field placed directly inside `tabs` (not wrapped in a `tab`) is treated as
  an implicit single-field tab.
- Bare top-level fields (not inside a panel/tab) are grouped into a default card.
- Containers are pruned per view: a tab/panel whose fields are all hidden on a view
  (via `only_on` / `hide_on`) isn't rendered there.
- The **index** view ignores grouping and shows the flattened, visible fields as columns.

### Redundant-label de-duplication

To avoid showing the same word twice, two labels are suppressed automatically:

- A **tab `description:` that equals the tab name** isn't rendered (the tab bar already shows
  the name).
- A **panel `name:` that equals the name of the tab containing it** isn't rendered (so a
  `tab "Permissions" { panel name: "Permissions" { … } }` shows the title once, not twice).

Distinct descriptions and panel names still render normally.

## Tab switching (JavaScript)

Tabs render as **stacked, titled cards without JavaScript**. With the bundled JS, the tab bar
is revealed, the redundant per-panel headings are hidden, and clicking a tab shows only that
panel (no server round-trip). See [JavaScript](../customization/javascript.md#tabs).

### Lazy tab loading

With `config.lazy_tabs = true`, only the **first (active) tab** of each group renders up front;
the others fetch their content the first time they're opened (showing a spinner meanwhile),
so their fields and association queries only run on demand. This is handy for show pages with
several heavy association tabs. Without JS the active tab still renders and the deferred tabs
show a "requires JavaScript" notice. See
[JavaScript › Lazy tabs](../customization/javascript.md#lazy-tabs).
