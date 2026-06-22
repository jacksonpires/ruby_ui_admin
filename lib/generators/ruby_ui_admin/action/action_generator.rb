# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    class ActionGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:action"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a RubyUI Admin action."

      class_option :standalone, type: :boolean, default: false,
        desc: "Action does not require selected records"

      def create_action
        template "action.rb.tt", File.join("app/ruby_ui_admin/actions", "#{file_path}.rb")
      end
    end
  end
end
