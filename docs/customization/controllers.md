# Custom controllers & lifecycle hooks

Each resource is served by a generic `RubyUIAdmin::ResourcesController`. To customize CRUD
behaviour for one resource, generate a per-resource controller:

```bash
rails g ruby_ui_admin:controller Buyer
# => app/controllers/ruby_ui_admin/buyers_controller.rb
#    class RubyUIAdmin::BuyersController < RubyUIAdmin::ResourcesController
```

When that file exists, the resource's routes point to it automatically (otherwise they use
the generic controller). Restart the server after adding a new controller so routes redraw.

## Lifecycle hooks

Override any of these (defaults live in `ResourcesController`):

| Hook | Default | When |
|---|---|---|
| `create_success_action` | redirect to `after_create_path`, flash notice | record saved on create |
| `create_fail_action` | re-render the form (422) | validation failed on create |
| `update_success_action` | redirect to `after_update_path`, flash notice | record saved on update |
| `update_fail_action` | re-render the form (422) | validation failed on update |
| `destroy_success_action` | redirect to `after_destroy_path`, flash notice | record destroyed |
| `destroy_fail_action` | redirect to the record, flash alert | `destroy` returned false |
| `after_create_path` / `after_update_path` | the record's show page | used by the success actions |
| `after_destroy_path` | the resource index | used by destroy success |

```ruby
module RubyUIAdmin
  class BuyersController < RubyUIAdmin::ResourcesController
    # Custom redirect + flash after update
    def update_success_action
      redirect_to resources_index_path, notice: "Buyer updated."
    end

    # Delete asynchronously instead of inline
    def destroy_fail_action
      Buyers::DeleteBuyerJob.perform_later(buyer: @record)
      redirect_to resources_index_path, notice: "Deletion started in the background."
    end
  end
end
```

Inside hooks you have the usual controller context: `@record`, `@resource`, `params`,
`current_user`, `redirect_to`/`render`, `flash`, and the path helpers `resources_index_path`
and `record_path(record)`.

## Overriding the CRUD actions

You can also override `create`, `update`, `destroy` (etc.) directly and call `super`:

```ruby
def create
  # custom param munging…
  super
end
```

Prefer the [eject generator](ejecting.md) for changing the generic controller or views.
