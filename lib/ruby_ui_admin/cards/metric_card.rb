# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    # Displays a single value (e.g. a count). Override `query` to return it.
    class MetricCard < BaseCard
      register_type :metric

      def value
        query
      end

      def prefix
        options[:prefix]
      end

      def suffix
        options[:suffix]
      end
    end
  end
end
