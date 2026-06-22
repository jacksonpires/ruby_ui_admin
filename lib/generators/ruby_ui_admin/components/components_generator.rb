# frozen_string_literal: true

require "rails/generators/base"

module RubyUIAdmin
  module Generators
    # Generates the RubyUI components the admin's views render, by shelling out to
    # `ruby_ui:component` once per component (RubyUI's generator takes one at a time). Without these,
    # the admin references `RubyUI::*` constants your app hasn't generated and blows up with a
    # NameError — this automates installing exactly the set it needs.
    #
    #   rails g ruby_ui_admin:components
    #
    # Safe to re-run: passes `--skip`, so components you already have are left untouched.
    class ComponentsGenerator < Rails::Generators::Base
      namespace "ruby_ui_admin:components"

      desc "Generates the RubyUI components the admin renders (via ruby_ui:component, one per command)."

      # The RubyUI components the admin's views reference. These are RubyUI *group* names (what you
      # pass to `ruby_ui:component`), not individual classes:
      #   - Typography provides InlineLink (there is no standalone `InlineLink` component).
      #   - Card/Table/Sidebar/Combobox each bring their whole family (CardHeader, TableRow, …).
      #   - Sheet isn't rendered directly — it's a dependency of RubyUI's mobile Sidebar.
      # Kept in sync with the engine by test/generators/generators_test.rb.
      COMPONENTS = %w[
        Card Badge Button Checkbox Combobox Typography Link Input Textarea Table Sidebar Sheet
      ].freeze

      def generate_components
        say "Generating the #{COMPONENTS.size} RubyUI components the admin needs " \
            "(one ruby_ui:component call each)…", :green

        COMPONENTS.each do |component|
          run "bin/rails generate ruby_ui:component #{component} --skip"
        end

        say "\nDone. Re-run any time — existing components are skipped, not overwritten.", :green
        say "If these fail, install RubyUI first (see docs/getting-started/installation.md).", :yellow
      end
    end
  end
end
