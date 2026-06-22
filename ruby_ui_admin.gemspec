# frozen_string_literal: true

require_relative "lib/ruby_ui_admin/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_ui_admin"
  spec.version = RubyUIAdmin::VERSION
  spec.authors = ["Jackson Pires"]
  spec.email = ["jackson.pires@gmail.com"]

  spec.summary = "A Rails admin dashboard engine built with RubyUI/Phlex and action_policy."
  spec.description = "ruby_ui_admin is an admin framework for Rails, " \
                     "rendered with RubyUI (Phlex) components and authorized with action_policy."
  spec.homepage = "https://github.com/jacksonpires/ruby_ui_admin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Exclude the demo media under docs/assets (gif/mp4) so they don't bloat the packaged gem.
  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "config/**/*",
    "public/**/*",
    "docs/**/*",
    "README.md",
    "MIT-LICENSE"
  ].reject { |f| f.start_with?("docs/assets/") }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "phlex-rails", ">= 2.0"
  spec.add_dependency "tailwind_merge", ">= 1.4"
  spec.add_dependency "action_policy", ">= 0.7"
  spec.add_dependency "pagy", "~> 9.0"
  spec.add_dependency "turbo-rails", ">= 2.0"
  spec.add_dependency "zeitwerk", ">= 2.6"

  # Development dependencies
  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "sqlite3", ">= 1.4"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "rake", ">= 13.0"
end
