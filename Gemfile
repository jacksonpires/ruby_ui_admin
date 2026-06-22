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
  # PoC (Option 3): render with host's RubyUI components. Generator/eject source.
  gem "ruby_ui", github: "ruby-ui/ruby_ui", branch: "main", require: false
  # Optional authorization backends (adapters): exercised by the test suite. Hosts add the one
  # they use. The gem requires these lazily, only when the matching authorization_client is selected.
  gem "pundit", require: false
  gem "cancancan", require: false
  # Dev-only docs browser (<mount>/docs): renders the gem's docs/*.md. Required lazily by
  # DocsController; hosts that want the in-app docs viewer add these to their own :development group.
  gem "kramdown", require: false
  gem "kramdown-parser-gfm", require: false
end
