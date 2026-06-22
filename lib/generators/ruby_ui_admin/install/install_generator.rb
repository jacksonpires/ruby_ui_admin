# frozen_string_literal: true

require "rails/generators/base"

module RubyUIAdmin
  module Generators
    class InstallGenerator < Rails::Generators::Base
      namespace "ruby_ui_admin:install"
      source_root File.expand_path("templates", __dir__)

      desc "Creates the RubyUI Admin initializer and mounts the engine."

      class_option :path, type: :string, default: "admin",
        desc: "Path to mount the admin at (default: admin)"

      def create_initializer
        template "initializer.rb.tt", "config/initializers/ruby_ui_admin.rb"
      end

      def mount_engine
        route %(mount_ruby_ui_admin at: "/#{options[:path]}")
      end

      def done
        say "\nRubyUI Admin: initializer created and engine mounted.", :green
        warn_if_ruby_ui_missing
        say "\nThe admin renders your app's RubyUI components + assets, so finish wiring them:", :yellow
        say "  1. Install RubyUI and generate its components (if you haven't). Run phlex:install"
        say "     FIRST — RubyUI's installer skips it when phlex-rails is present (it is, via this"
        say "     gem) and then aborts on a missing app/components/base.rb:"
        say "       bin/rails generate phlex:install"
        say "       bin/rails generate ruby_ui:install"
        say "     Then generate the components the admin needs (drives ruby_ui:component for you):"
        say "       bin/rails generate ruby_ui_admin:components"
        say "  2. Tailwind: extract the admin's classes into your app and @source the result:"
        say "       bin/rails ruby_ui_admin:tailwind_source   # writes app/assets/tailwind/ruby_ui_admin_classes.html"
        say %(       @source "./ruby_ui_admin_classes.html";  # in your Tailwind entry CSS (commit the file))
        say "  3. Stimulus: copy the admin's controllers into your app with"
        say "       bin/rails generate ruby_ui_admin:assets"
        say "     then add the one import line it prints to app/javascript/application.js."
        say "  4. Set config.head_assets in config/initializers/ruby_ui_admin.rb (see the comment there)."
        say "\nFull guide: docs/getting-started/installation.md", :green
        say "Then generate your first resource:"
        say "  bin/rails generate ruby_ui_admin:resource <Model>\n"
      end

      private

      # RubyUI's installer aborts (leaving RubyUI::Base ungenerated) if it runs before
      # phlex:install on an app that already has phlex-rails — which every ruby_ui_admin app does.
      # Surface that here so a half-installed RubyUI doesn't show up later as a cryptic Zeitwerk error.
      def warn_if_ruby_ui_missing
        return if File.exist?(Rails.root.join("app/components/ruby_ui/base.rb"))

        say "\n⚠️  RubyUI doesn't look fully installed (app/components/ruby_ui/base.rb is missing).", :red
        say "    RubyUI's `ruby_ui:install` aborts on a missing app/components/base.rb when phlex-rails", :red
        say "    is already present (it is, via this gem). Run `bin/rails generate phlex:install` first,", :red
        say "    then re-run `bin/rails generate ruby_ui:install`.", :red
      end
    end
  end
end
