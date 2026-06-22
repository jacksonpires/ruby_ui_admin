# Internationalization (i18n)

The admin is localized through Rails i18n. Each admin request runs inside
`I18n.with_locale(config.locale)` when a locale is configured.

```ruby
RubyUIAdmin.configure do |config|
  config.locale = :"pt-BR"
  # or resolve per request from your controller, e.g. config.locale = I18n.locale
end
```

There are two layers of translation:

## 1. Framework strings (bundled)

Built-in UI text — buttons, table headers, the empty state, pagination, boolean badges — is
translated under the `ruby_ui_admin.*` namespace. The gem ships **English** and
**Brazilian Portuguese** out of the box, auto-loaded into `I18n`.

Copy them into your app to edit or add locales:

```bash
rails g ruby_ui_admin:locales   # -> config/locales/ruby_ui_admin.en.yml, ruby_ui_admin.pt-BR.yml
```

Add another language by creating `config/locales/ruby_ui_admin.<locale>.yml` with the same keys.

## 2. Domain labels (your app's translations)

Resource and field labels use standard Rails i18n, so they read from **your** locale files:

- **Field labels** use `Model.human_attribute_name`, i.e. `activerecord.attributes.<model>.<attr>`.
- They fall back to a humanized name when there's no translation.

```yaml
# config/locales/pt-BR.yml
"pt-BR":
  activerecord:
    attributes:
      post:
        title: "Título"
        published: "Publicado"
```

With the locale set to `pt-BR`, the Post resource's `title` field renders as “Título”.

> Action names are plain strings you set with `self.name`; localize them by setting the name
> from a translation in your action (e.g. `self.name = I18n.t("...")` is evaluated at load —
> prefer a fixed string or your own lookup if you need per-request locales).
