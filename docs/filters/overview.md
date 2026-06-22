# Filters — Overview

Filters narrow the index query. Define them in `app/ruby_ui_admin/filters` under
`RubyUIAdmin::Filters`, then attach them to a resource with `def filters`.

```ruby
module RubyUIAdmin
  module Filters
    class StatusFilter < RubyUIAdmin::Filters::SelectFilter
      self.name = "Status"

      def apply(request, query, value)
        query.where(status: value)
      end

      def options
        {"draft" => "Draft", "published" => "Published"}
      end
    end
  end
end
```

Attach to a resource:

```ruby
def filters
  filter RubyUIAdmin::Filters::StatusFilter
  filter RubyUIAdmin::Filters::TitleFilter
end
```

## Filter types

Inherit from one of these base classes:

| Base class | Control | Implement |
|---|---|---|
| `RubyUIAdmin::Filters::TextFilter` | text input | `apply(request, query, value)` |
| `RubyUIAdmin::Filters::SelectFilter` | dropdown | `apply` + `options` (Hash `{value => label}`) |
| `RubyUIAdmin::Filters::MultipleSelectFilter` | checkbox group | `apply` + `options`; `value` is an **Array** of checked keys |
| `RubyUIAdmin::Filters::BooleanFilter` | Yes/No dropdown, or a checkbox group | `apply`; without `options` the value is `"true"`/`"false"`. With `options` (`{key => label}`) it renders one checkbox per key and `value` is a **Hash** `{key => "true"/"false"}` |

> Checkbox-group filters (`MultipleSelectFilter`, and `BooleanFilter` with `options`) render with
> RubyUI's **Combobox** — a trigger showing the selected count plus a searchable popover of
> checkboxes — so filters with many options stay compact. (The Combobox is Stimulus-driven.)

## How it works

- Each filter renders a control in the filter bar above the index table.
- Submitting the bar reloads the index with `?filters[<key>]=<value>`.
- The `<key>` is derived from the class name (e.g. `StatusFilter` → `status_filter`).
- Blank values are ignored (the filter's `apply` isn't called).
- Filters compose with the policy scope and sorting.

## Default value

Override `default` to pre-apply a filter when its param isn't submitted (e.g. on first load).
An explicitly-cleared filter (submitted blank) overrides the default.

```ruby
def default
  "published"
end
```

## Arguments

Pass `arguments:` when attaching and read them via `arguments` in `apply`:

```ruby
filter RubyUIAdmin::Filters::NameFilter, arguments: {case_insensitive: true}
```
