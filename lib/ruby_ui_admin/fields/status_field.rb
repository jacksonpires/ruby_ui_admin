# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Renders the value as a status badge with a leading dot. Configure with
    # `options: { success: %w[done], warning: %w[pending], danger: %w[failed] }`.
    class StatusField < BaseField
      register_as :status

      VARIANT_FOR_STATE = {success: :success, warning: :warning, danger: :destructive, info: :primary}.freeze

      def variant_for(record)
        current = value(record).to_s
        states = options[:options] || {}

        state = states.find { |_key, values| Array(values).map(&:to_s).include?(current) }&.first
        VARIANT_FOR_STATE.fetch(state&.to_sym, :gray)
      end
    end
  end
end
