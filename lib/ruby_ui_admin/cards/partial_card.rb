# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    # Renders arbitrary HTML returned by `query` (or `body`).
    class PartialCard < BaseCard
      register_type :partial

      def body
        query
      end
    end
  end
end
