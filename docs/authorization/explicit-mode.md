# Explicit authorization mode

`config.explicit_authorization` controls what happens when authorization can't find an
explicit answer.

```ruby
RubyUIAdmin.configure do |config|
  config.explicit_authorization = false # default
end
```

## What it affects

### Resource & action rules

For `index?/show?/create?/update?/destroy?/act_on?`, a rule the policy doesn't define falls
back to the policy's default rule (`manage?`), which `RubyUIAdmin::BasePolicy` ties to this
flag:

| `explicit_authorization` | Undefined rule | No policy resolved at all |
|---|---|---|
| `false` (default) | **allowed** | **allowed** |
| `true` | **denied** | **denied** |

So `true` is a strict, deny-by-default posture: every allowed action must be declared in a
policy. This matches a security-first setup.

### Field rules

Field/association visibility (`view_<field>?`) is **not** governed by this flag. A field is
always visible unless a policy explicitly defines its rule and returns false. This is
deliberate — turning on `explicit_authorization` must not silently hide every unconfigured
field. See [Field-level authorization](field-authorization.md).

## Disabling authorization

Set `config.authorization_client = nil` to turn authorization off entirely (all rules pass,
scopes are not applied). Useful for a trusted internal tool, or while bootstrapping.

## Choosing a mode

- **`false`** — convenient: define only the rules that restrict access; everything else is
  open. Good default for small teams / trusted admins.
- **`true`** — strict: nothing is permitted unless a policy says so. Prefer this when the
  admin is exposed to many roles and you want fail-closed behaviour.
