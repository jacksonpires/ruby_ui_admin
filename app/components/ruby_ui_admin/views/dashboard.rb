# frozen_string_literal: true

module RubyUIAdmin
  module Views
    class Dashboard < Base
      def initialize(dashboard:)
        @dashboard = dashboard
      end

      def page_title
        "#{@dashboard.class.title} · #{RubyUIAdmin.configuration.app_name}"
      end

      def content
        div(class: "mb-6") do
          h1(class: "text-2xl font-semibold tracking-tight") { @dashboard.class.title }
          if (description = @dashboard.class.description)
            p(class: "text-sm text-muted-foreground mt-1") { description }
          end
        end

        cards = @dashboard.get_cards
        if cards.empty?
          p(class: "text-muted-foreground") { "No cards defined yet." }
        else
          div(class: grid_class) do
            cards.each { |card| render RubyUIAdmin::Views::CardComponent.new(card: card) }
          end
        end
      end

      private

      def grid_class
        columns = @dashboard.class.grid_columns.to_i.clamp(1, 4)
        "grid gap-4 md:grid-cols-#{columns}"
      end
    end
  end
end
