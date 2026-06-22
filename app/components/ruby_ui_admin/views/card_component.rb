# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Renders a single dashboard card, dispatching on the card type.
    class CardComponent < Phlex::HTML
      include RubyUIAdmin::UI

      def initialize(card:)
        @card = card
      end

      def view_template
        render RubyUI::Card.new(class: span_class) do
          render RubyUI::CardHeader.new do
            render RubyUI::CardTitle.new(class: "text-sm font-medium text-muted-foreground") { @card.label }
          end
          render RubyUI::CardContent.new do
            render_body
          end
        end
      end

      private

      def span_class
        width = @card.width.to_i
        width > 1 ? "md:col-span-#{width}" : ""
      end

      def render_body
        case @card.type
        when :metric then render_metric
        when :chart then render_chart
        when :partial then raw(safe(@card.body.to_s))
        else plain(@card.query.to_s)
        end
      end

      def render_metric
        div(class: "text-3xl font-semibold tracking-tight") do
          plain [@card.prefix, @card.value, @card.suffix].compact.join
        end
      end

      def render_chart
        data = @card.data
        return plain("—") if data.empty?

        max = data.values.map(&:to_f).max
        max = 1.0 if max.zero?

        div(class: "space-y-2") do
          data.each do |label, value|
            div(class: "space-y-1") do
              div(class: "flex justify-between text-xs text-muted-foreground") do
                span { label.to_s }
                span { value.to_s }
              end
              div(class: "h-2 rounded bg-muted") do
                div(class: "h-2 rounded bg-primary", style: "width: #{(value.to_f / max * 100).round(1)}%")
              end
            end
          end
        end
      end
    end
  end
end
