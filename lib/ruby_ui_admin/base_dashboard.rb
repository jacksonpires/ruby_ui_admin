# frozen_string_literal: true

module RubyUIAdmin
  # Base class for dashboards. Host dashboards (RubyUIAdmin::Dashboards::*) inherit
  # this and declare cards in `def cards`.
  class BaseDashboard
    class << self
      # Class-level `self.name =` with fallback to the real class name.
      def name=(value)
        @display_name = value
      end

      def name
        @display_name || super
      end

      def id=(value)
        @id = value
      end

      def id
        (defined?(@id) && @id) || to_s.demodulize.underscore
      end

      def description=(value)
        @description = value
      end

      def description
        defined?(@description) ? @description : nil
      end

      def grid_columns=(value)
        @grid_columns = value
      end

      def grid_columns
        (defined?(@grid_columns) && @grid_columns) || 3
      end

      # Display title (falls back to a humanized class name).
      def title
        @display_name || to_s.demodulize.titleize
      end

      def abstract?
        self == RubyUIAdmin::BaseDashboard
      end
    end

    # Overridden by subclasses to declare cards.
    def cards; end

    def card(klass, **options)
      card_items << {klass: klass, options: options}
    end

    def divider(**); end

    def card_items
      @card_items ||= []
    end

    def get_cards
      @card_items = []
      cards
      card_items.map { |entry| entry[:klass].new(**(entry[:options] || {})) }
    end
  end
end
