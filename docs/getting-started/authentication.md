# Authentication

RubyUI Admin doesn't ship its own login system — it plugs into your host app's
authentication. Two configuration blocks control it:

- **`current_user_method`** — who the current admin is.
- **`authenticate_with`** — whether the request is allowed in at all.

Both run with `instance_exec` **inside the admin controller**, so any helper available in
your controllers (Devise's `current_user`, `authenticate_user!`, `redirect_to`,
`main_app.*`, sessions, etc.) is available inside the block.

## Resolving the current user

```ruby
RubyUIAdmin.configure do |config|
  config.current_user_method { current_user }
end
```

The block's return value becomes the user passed to policies (action_policy's `user`
context) and shown in the top bar. Both arities work:

```ruby
config.current_user_method { current_user }                   # no args
config.current_user_method { |context| context.current_user } # receives the controller
```

The resolved user is also available globally during the request as `RubyUIAdmin::Current.user`.

## Gating access

`authenticate_with` runs as a `before_action` on every admin request. Use it to require a
session and/or an admin flag:

```ruby
RubyUIAdmin.configure do |config|
  config.authenticate_with do
    redirect_to main_app.login_path unless current_user&.admin?
  end
end
```

If the block renders or redirects, the request stops there. If it does nothing, the request
proceeds.

## Example with Devise

```ruby
RubyUIAdmin.configure do |config|
  config.current_user_method { current_user }

  config.authenticate_with do
    authenticate_user!                       # Devise: bounce anonymous users to login
    unless current_user.admin?
      redirect_to main_app.root_path, alert: "Not authorized"
    end
  end
end
```

You can also gate access at the routing layer instead, mounting the engine inside a
Devise `authenticate` block:

```ruby
# config/routes.rb
authenticate :user, ->(u) { u.admin? } do
  mount_ruby_ui_admin at: "/admin"
end
```

## Authorization vs. authentication

- **Authentication** (this page) decides *who you are* and *whether you may enter the admin*.
- **Authorization** decides *what you may do* per resource/record — handled by action_policy.
  See [Authorization](../authorization/action-policy.md).

## Notes

- Without `current_user_method`, `RubyUIAdmin::Current.user` is `nil` and policies receive a
  `nil` user — fine if your policies handle it, but usually you want it set.

## Sign-out link

Set `config.sign_out_path_name` to a host route helper and a sign-out button renders
automatically at the bottom of the sidebar (with the current user's label above it, when
available). The button submits a form to `main_app.<sign_out_path_name>`; the HTTP method is
`config.sign_out_method` (default `:delete`). For Devise:

```ruby
RubyUIAdmin.configure do |config|
  config.sign_out_path_name = :destroy_user_session_path
  config.sign_out_method = :delete   # default
end
```

If `sign_out_path_name` is unset (the default), no sign-out button is rendered. See the full
options table in [Configuration](configuration.md).
