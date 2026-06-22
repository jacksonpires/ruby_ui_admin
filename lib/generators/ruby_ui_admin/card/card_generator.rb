# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    class CardGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:card"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a RubyUI Admin card. Use --type metric|chart|partial."

      class_option :type, type: :string, default: "metric",
        desc: "Card type: metric, chart or partial"

      def create_card
        template "#{card_type}_card.rb.tt", File.join("app/ruby_ui_admin/cards", "#{file_path}.rb")
      end

      private

      def card_type
        type = options[:type].to_s
        %w[metric chart partial].include?(type) ? type : "metric"
      end
    end
  end
end
