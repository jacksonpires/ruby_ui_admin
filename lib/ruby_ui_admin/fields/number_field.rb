# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class NumberField < BaseField
      register_as :number

      def step = options[:step]
      def min = options[:min]
      def max = options[:max]
    end
  end
end
