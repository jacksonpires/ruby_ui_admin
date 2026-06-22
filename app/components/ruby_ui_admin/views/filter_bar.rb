# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Renders a GET form with one control per filter, above the index table.
    class FilterBar < Phlex::HTML
      include RubyUIAdmin::UI
      include Translation

      def initialize(filters:, values:, action_path:, scope_param: nil)
        @filters = filters
        @values = values || {}
        @action_path = action_path
        @scope_param = scope_param
      end

      def view_template
        return if @filters.empty?

        render RubyUI::Card.new(class: "mb-4") do
          render RubyUI::CardContent.new(class: "pt-6") do
            form(method: "get", action: @action_path, class: "flex flex-wrap items-end gap-4") do
              # Preserve the active scope when applying filters.
              input(type: "hidden", name: "scope", value: @scope_param) if @scope_param.present?

              @filters.each { |filter| render_filter(filter) }
              render_buttons
            end
          end
        end
      end

      private

      def render_filter(filter)
        key = filter.param_key

        div(class: "space-y-1 min-w-48") do
          label(class: "text-xs font-medium text-muted-foreground") { filter.name }

          case filter.type
          when :select
            render RubyUIAdmin::UI::Select.new(name: "filters[#{key}]", options: option_pairs(filter), selected: @values[key], include_blank: true)
          when :multiple_select
            render_checkboxes(filter, key, multiple: true)
          when :boolean
            if filter.options.present?
              render_checkboxes(filter, key, multiple: false)
            else
              render RubyUIAdmin::UI::Select.new(name: "filters[#{key}]", options: [["Yes", "true"], ["No", "false"]], selected: @values[key], include_blank: true)
            end
          else
            render RubyUI::Input.new(type: :text, name: "filters[#{key}]", value: @values[key])
          end
        end
      end

      # Renders the option set with RubyUI's Combobox (searchable popover with checkboxes),
      # so filters with many options stay compact and match the rest of the RubyUI UI.
      #
      # `multiple: true`  -> array value, name `filters[key][]`.
      # `multiple: false` -> hash value (boolean filter), name `filters[key][optkey]` with a
      #                      paired hidden "false" so unchecked boxes are still submitted.
      def render_checkboxes(filter, key, multiple:)
        selected = @values[key]

        render RubyUI::Combobox.new(term: rua_t("index.selected_suffix")) do
          render RubyUI::ComboboxTrigger.new(placeholder: rua_t("index.all"))
          render RubyUI::ComboboxPopover.new do
            render RubyUI::ComboboxSearchInput.new(placeholder: rua_t("index.search"))
            render RubyUI::ComboboxList.new do
              render(RubyUI::ComboboxEmptyState.new) { rua_t("index.no_results") }
              option_pairs(filter).each do |(label_text, value)|
                input_name = multiple ? "filters[#{key}][]" : "filters[#{key}][#{value}]"
                render RubyUI::ComboboxItem.new do
                  input(type: :hidden, name: input_name, value: "false") unless multiple
                  render RubyUI::ComboboxCheckbox.new(
                    name: input_name,
                    value: multiple ? value.to_s : "true",
                    checked: checkbox_checked?(selected, value, multiple)
                  )
                  span { label_text }
                end
              end
            end
          end
        end
      end

      def checkbox_checked?(selected, value, multiple)
        if multiple
          Array(selected).map(&:to_s).include?(value.to_s)
        else
          selected.is_a?(Hash) && selected[value.to_s].to_s == "true"
        end
      end

      def option_pairs(filter)
        options = filter.options
        options.is_a?(Hash) ? options.map { |value, label| [label, value] } : Array(options)
      end

      def render_buttons
        div(class: "flex items-center gap-2") do
          render(RubyUI::Button.new(type: :submit, variant: :primary)) { rua_t("index.filter") }
          a(href: @action_path, class: "text-sm text-muted-foreground hover:underline") { rua_t("index.clear") }
        end
      end
    end
  end
end
