# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in ruby_ui_admin.gemspec
gemspec

group :development, :test do
  gem "puma"
  gem "propshaft"
  gem "importmap-rails"
  gem "stimulus-rails"
  gem "tailwindcss-rails"
  # The admin renders the host's RubyUI components (test/dummy/app/components/ruby_ui mirrors
  # ruby_ui 1.6.0). Pinned to the released gem: ruby_ui's unreleased `main` rewrote Combobox
  # (no ComboboxPopover/ComboboxTrigger/…), which the admin's views don't support yet.
  gem "ruby_ui", "~> 1.6", require: false
  # Optional authorization backends (adapters): exercised by the test suite. Hosts add the one
  # they use. The gem requires these lazily, only when the matching authorization_client is selected.
  gem "pundit", require: false
  gem "cancancan", require: false
  # Dev-only docs browser (<mount>/docs): renders the gem's docs/*.md. Required lazily by
  # DocsController; hosts that want the in-app docs viewer add these to their own :development group.
  gem "kramdown", require: false
  gem "kramdown-parser-gfm", require: false
end
