# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    class FilterGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:filter"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a RubyUI Admin filter. Use --type text|select|boolean."

      class_option :type, type: :string, default: "text",
        desc: "Filter type: text, select or boolean"

      def create_filter
        template "#{filter_type}_filter.rb.tt", File.join("app/ruby_ui_admin/filters", "#{file_path}_filter.rb")
      end

      private

      def filter_type
        type = options[:type].to_s
        %w[text select boolean].include?(type) ? type : "text"
      end
    end
  end
end
