# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    class PolicyGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:policy"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a RubyUI Admin action_policy policy."

      def create_policy
        template "policy.rb.tt", File.join("app/ruby_ui_admin/policies", "#{file_path}_policy.rb")
      end
    end
  end
end
