# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class BooleanField < BaseField
      register_as :boolean

      def checked?(record)
        !!value(record)
      end
    end
  end
end
