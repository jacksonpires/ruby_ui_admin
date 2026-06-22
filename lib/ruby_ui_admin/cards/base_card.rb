# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    # Base class for dashboard cards. Subclasses override `query` to compute their
    # value/data. Mirrors the Filters pattern: base types live here and host cards
    # (RubyUIAdmin::Cards::*) inherit them.
    class BaseCard
      class << self
        attr_writer :label, :width

        def label
          (defined?(@label) && @label) || to_s.demodulize.titleize
        end

        def width
          (defined?(@width) && @width) || 1
        end

        # Inherited down the chain (subclasses of MetricCard are :metric, etc.).
        def card_type
          return @card_type if defined?(@card_type) && @card_type
          return superclass.card_type if superclass.respond_to?(:card_type)

          nil
        end

        def register_type(type)
          @card_type = type.to_sym
        end
      end

      attr_reader :options

      def initialize(**options)
        @options = options
      end

      def label
        self.class.label
      end

      def width
        self.class.width
      end

      def type
        self.class.card_type
      end

      def card_id
        self.class.to_s.demodulize.underscore
      end

      # Override in subclasses to compute the card's value/data.
      def query; end
    end
  end
end
