# frozen_string_literal: true

# Vendored from RubyUI (github.com/ruby-ui), namespaced under RubyUIAdmin::UI.
module RubyUIAdmin
  module UI
    class ToastDescription < Base
      def view_template(&)
        div(**attrs, &)
      end

      private

      def default_attrs
        {
          data: {slot: "description"},
          class: "font-normal leading-[1.4] text-muted-foreground"
        }
      end
    end
  end
end
