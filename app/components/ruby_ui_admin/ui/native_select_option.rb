# frozen_string_literal: true

# Vendored from RubyUI (github.com/ruby-ui), namespaced under RubyUIAdmin::UI.
module RubyUIAdmin
  module UI
    class NativeSelectOption < Base
      def view_template(&)
        option(**attrs, &)
      end

      private

      def default_attrs
        {}
      end
    end
  end
end
