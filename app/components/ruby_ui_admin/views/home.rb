# frozen_string_literal: true

module RubyUIAdmin
  module Views
    class Home < Base
      def initialize(resources:)
        @resources = resources
      end

      def content
        h1(class: "text-2xl font-semibold tracking-tight mb-6") { RubyUIAdmin.configuration.app_name }

        if @resources.empty?
          p(class: "text-muted-foreground") { "No resources defined yet. Create one in app/ruby_ui_admin/resources." }
        else
          div(class: "grid gap-4 sm:grid-cols-2 lg:grid-cols-3") do
            @resources.each { |rc| render_card(rc) }
          end
        end
      end

      private

      def render_card(rc)
        a(href: resource_index_path(rc), class: "block") do
          render RubyUI::Card.new(class: "hover:shadow-md transition-shadow") do
            render RubyUI::CardHeader.new do
              render RubyUI::CardTitle.new { rc.navigation_label }
            end
          end
        end
      end
    end
  end
end
