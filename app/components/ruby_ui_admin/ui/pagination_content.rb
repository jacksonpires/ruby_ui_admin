# frozen_string_literal: true

# Vendored from RubyUI (github.com/ruby-ui), namespaced under RubyUIAdmin::UI.
module RubyUIAdmin
  module UI
    class PaginationContent < Base
      def view_template(&)
        ul(**attrs, &)
      end

      private

      def default_attrs
        {class: "flex flex-row items-center gap-1"}
      end
    end
  end
end
