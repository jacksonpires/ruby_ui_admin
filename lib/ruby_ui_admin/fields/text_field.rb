# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class TextField < BaseField
      register_as :text

      # Render the raw value as HTML (`as_html: true`).
      def as_html?
        !!options[:as_html]
      end
    end
  end
end
