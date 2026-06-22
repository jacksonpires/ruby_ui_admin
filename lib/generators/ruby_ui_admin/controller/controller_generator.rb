# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    # Generates a per-resource controller so you can override CRUD lifecycle hooks.
    #   rails g ruby_ui_admin:controller Buyer
    class ControllerGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:controller"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a per-resource controller (subclass of ResourcesController)."

      def create_controller
        template "controller.rb.tt", File.join("app/controllers/ruby_ui_admin", "#{plural_file_name}_controller.rb")
      end

      private

      def plural_file_name
        file_name.pluralize
      end

      def controller_class_name
        "#{class_name.pluralize}Controller"
      end
    end
  end
end
