# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    class DashboardGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:dashboard"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a RubyUI Admin dashboard."

      def create_dashboard
        template "dashboard.rb.tt", File.join("app/ruby_ui_admin/dashboards", "#{file_path}.rb")
      end
    end
  end
end
