# frozen_string_literal: true

module RubyUIAdmin
  module UI
    # Convenience wrapper around RubyUI's NativeSelect: takes an array of [label, value]
    # `options` (plus `selected:`/`include_blank:`) instead of explicit option components,
    # so call sites stay terse. Renders the styled native select with a custom chevron.
    class Select < Base
      def initialize(options: [], selected: nil, include_blank: false, **attrs)
        @options = options
        @selected = selected
        @include_blank = include_blank
        super(**attrs)
      end

      def view_template
        render NativeSelect.new(**attrs) do
          render(NativeSelectOption.new(value: "")) { "—" } if @include_blank

          @options.each do |(label, value)|
            opts = {value: value}
            opts[:selected] = true if value.to_s == @selected.to_s
            render(NativeSelectOption.new(**opts)) { label.to_s }
          end
        end
      end
    end
  end
end
