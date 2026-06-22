# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Password input on forms; never displays the stored value.
    class PasswordField < BaseField
      register_as :password

      def default_hidden_views
        %i[index show]
      end

      # Don't write a blank password back onto the record.
      def fill_value(record, value)
        return if value.blank?

        super
      end
    end
  end
end
