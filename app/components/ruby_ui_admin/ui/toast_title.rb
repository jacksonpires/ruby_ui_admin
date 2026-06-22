# frozen_string_literal: true

# Vendored from RubyUI (github.com/ruby-ui), namespaced under RubyUIAdmin::UI.
module RubyUIAdmin
  module UI
    class ToastTitle < Base
      def view_template(&)
        div(**attrs, &)
      end

      private

      def default_attrs
        {
          data: {slot: "title"},
          class: "font-medium leading-normal"
        }
      end
    end
  end
end
