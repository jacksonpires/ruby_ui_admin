# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    # Displays a simple bar chart from a {label => number} Hash returned by `query`.
    # (No charting JS dependency — rendered as horizontal bars.)
    class ChartCard < BaseCard
      register_type :chart

      def data
        result = query
        result.is_a?(Hash) ? result : {}
      end
    end
  end
end
