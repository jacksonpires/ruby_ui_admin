# Policies

Authorization is handled by [action_policy](https://actionpolicy.evilmartians.io). Admin
policies live in `app/ruby_ui_admin/policies` (`RubyUIAdmin::Policies::*`) and inherit
`RubyUIAdmin::BasePolicy`. Attach one to a resource with `self.authorization_policy`.

```ruby
# app/ruby_ui_admin/resources/post.rb
class Post < RubyUIAdmin::BaseResource
  self.authorization_policy = RubyUIAdmin::Policies::PostPolicy
end

# app/ruby_ui_admin/policies/post_policy.rb
module RubyUIAdmin
  module Policies
    class PostPolicy < RubyUIAdmin::BasePolicy
      def index?  = true
      def show?   = true
      def create? = user.admin?
      def update? = user.admin? || record.user_id == user.id
      def destroy? = user.admin?
      def act_on? = user.admin?      # gate custom actions
    end
  end
end
```

## Rule mapping

| Controller action | Rule | Target |
|---|---|---|
| index | `index?` | model class |
| show | `show?` | record |
| new / create | `create?` | record |
| edit / update | `update?` | record |
| destroy | `destroy?` | record |
| custom actions | `act_on?` | record(s) / model class |

Field- and association-level rules (`view_<field>?`, `show_<field>?`, …) are covered in
[Field-level authorization](field-authorization.md).

## Defaults

`RubyUIAdmin::BasePolicy` wires action_policy's default rule (`manage?`) to
[`explicit_authorization`](explicit-mode.md): a rule you don't define falls back to `manage?`,
which is allowed when `explicit_authorization` is false (the default) and denied when true.

`authorize :user` is declared with `allow_nil: true`, so rules must guard a possibly-nil user
(`user&.admin?`) when the admin can be reached without a signed-in user.

## Context

The `user` comes from `config.current_user_method`. `true_user` (the real user behind an
impersonation) is also available, resolved from `config.true_user_method` (defaults to the
current user) — gate on it with `true_user&.admin?`. To pass *additional* context (e.g. an
account), declare it in a custom base policy and provide it — see the
[action_policy docs](https://actionpolicy.evilmartians.io/#/authorization_context).

## The current user

`RubyUIAdmin::Current.user` exposes the resolved user during a request. In views, use
`authorized_to?(:rule, record, policy_class:)` to show/hide buttons and links.
