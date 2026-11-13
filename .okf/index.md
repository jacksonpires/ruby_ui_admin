---
okf_version: "0.2"
---

# RubyUI Admin — knowledge bundle

Knowledge, decisions and conventions for the `ruby_ui_admin` gem: a Rails admin engine that
renders the **host app's** RubyUI (Phlex) components and authorizes through pluggable adapters.
User-facing how-to documentation lives in the gem's `docs/`; this bundle records the *why* and
the cross-cutting mechanics behind it.

# Areas

* [Architecture](architecture/) - engine boot, resource registry, dynamic routes, request context and the proc-evaluation core
* [DSL](dsl/) - the declarative surfaces host apps write: resources, fields, actions, filters/scopes, dashboards, menu
* [Authorization](authorization/) - the adapter facade, the fallback semantics and field-level rules
* [Frontend](frontend/) - host-owned assets (Option 3), Hotwire-only behaviour, component ownership
* [Development](development/) - testing conventions, dev-reload gotchas, the in-app docs browser, ejecting
