# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class TextareaField < BaseField
      register_as :textarea

      def rows
        options[:rows] || 4
      end
    end
  end
end
