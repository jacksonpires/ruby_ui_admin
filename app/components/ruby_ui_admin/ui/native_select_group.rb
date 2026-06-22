# frozen_string_literal: true

# Vendored from RubyUI (github.com/ruby-ui), namespaced under RubyUIAdmin::UI.
module RubyUIAdmin
  module UI
    class NativeSelectGroup < Base
      def view_template(&)
        optgroup(**attrs, &)
      end

      private

      def default_attrs
        {}
      end
    end
  end
end
