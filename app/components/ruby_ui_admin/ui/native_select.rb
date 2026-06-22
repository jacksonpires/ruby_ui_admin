# frozen_string_literal: true

# Vendored from RubyUI (github.com/ruby-ui), namespaced under RubyUIAdmin::UI.
# Adapted for this engine: full-width (to match the other form inputs), using the
# engine's `input`/`background` tokens, and without RubyUI's FormField Stimulus hooks
# (not used here). A styled native <select> with a custom chevron — no JS needed.
module RubyUIAdmin
  module UI
    class NativeSelect < Base
      def initialize(size: :default, **attrs)
        @size = size
        super(**attrs)
      end

      def view_template(&block)
        div(class: "group/native-select relative w-full has-[select:disabled]:opacity-50") do
          select(**attrs, &block)
          render NativeSelectIcon.new
        end
      end

      private

      def default_attrs
        {
          class: [
            "border-input bg-background text-foreground text-sm w-full min-w-0 appearance-none rounded-md border py-1 pr-8 pl-3 shadow-sm transition-[color,box-shadow] outline-none",
            "focus-visible:outline-none focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-2",
            "disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50",
            "aria-invalid:ring-destructive/20 aria-invalid:border-destructive aria-invalid:ring-2",
            (@size == :sm) ? "h-8" : "h-9"
          ]
        }
      end
    end
  end
end
