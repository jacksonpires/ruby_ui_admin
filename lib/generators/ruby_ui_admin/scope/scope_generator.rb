# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    class ScopeGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:scope"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a RubyUI Admin named index scope."

      def create_scope
        template "scope.rb.tt", File.join("app/ruby_ui_admin/scopes", "#{file_path}.rb")
      end
    end
  end
end
