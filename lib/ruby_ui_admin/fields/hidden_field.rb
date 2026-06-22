# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Renders only as a hidden input on forms; not shown on index/show.
    class HiddenField < BaseField
      register_as :hidden

      def default_hidden_views
        %i[index show]
      end
    end
  end
end
