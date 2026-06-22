# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # An action button that opens an inline modal with the action form. Without JS the
    # button is a plain link to the action page (Views::Action), so it always works.
    class ActionTrigger < Phlex::HTML
      include RubyUIAdmin::UI
      include RailsHelpers
      include PathHelpers

      # `bulk: true` renders a submit button tied (via the HTML `form` attribute) to the
      # bulk-selection form `form_id`, so without JS it submits the checked rows to the
      # action page. With JS the checked ids are injected into the modal form instead.
      # `part:` controls what is rendered — `:both` (default), `:trigger` (just the button/link)
      # or `:dialog` (just the modal). When triggers live inside the actions Combobox, the dialogs
      # are rendered separately (outside the popover) so closing it doesn't hide the open modal.
      # `as_menu_item: true` styles the trigger to fill a Combobox item row.
      def initialize(resource:, action:, record_ids: [], bulk: false, form_id: nil, part: :both, as_menu_item: false)
        @resource = resource
        @action = action
        @record_ids = record_ids
        @bulk = bulk
        @form_id = form_id
        @part = part
        @as_menu_item = as_menu_item
      end

      def view_template
        render_trigger unless @part == :dialog
        render_dialog unless @part == :trigger
      end

      private

      def render_trigger
        if @bulk
          button(
            type: "submit",
            form: @form_id,
            formaction: page_path,
            formmethod: "get",
            data: trigger_data,
            class: trigger_classes
          ) { @action.name }
        else
          a(href: action_path, data: trigger_data, class: trigger_classes) { @action.name }
        end
      end

      # Data attributes for the trigger. The `rua--dialog#open` Stimulus action opens the lazy
      # modal (passing the dialog id / bulk flag as action params). Inside the actions Combobox
      # the item is also a combobox `input` target (so the search box filters it) and closes the
      # popover on click — both actions chain on `click`.
      def trigger_data
        actions = ["click->rua--dialog#open"]
        data = {rua__dialog_id_param: dialog_id}
        # String "true" (not boolean) so Phlex renders `...-bulk-param="true"` and Stimulus
        # type-casts the action param back to boolean `true` (a boolean would render an empty
        # attribute, which Stimulus reads as the string "").
        data[:rua__dialog_bulk_param] = "true" if @bulk
        if @as_menu_item
          data[:ruby_ui__combobox_target] = "input"
          actions << "click->ruby-ui--combobox#closePopover"
        end
        data[:action] = actions.join(" ")
        data
      end

      # Inside the actions Combobox the trigger fills the item row (the surrounding ComboboxItem
      # supplies the hover/padding). Standalone it is a normal outline button.
      def trigger_classes
        if @as_menu_item
          "block w-full whitespace-nowrap text-left text-sm"
        else
          "inline-flex items-center h-9 px-4 rounded-md border border-input bg-background text-sm font-medium shadow-sm hover:bg-accent"
        end
      end

      def action_key
        @action.class.action_key
      end

      def dialog_id
        "rua-action-#{action_key}-#{@bulk ? "bulk" : (@record_ids.first || "all")}"
      end

      def page_path
        ruby_ui_admin.resource_action_path(resource_name: @resource.route_key, action_id: action_key)
      end

      def action_path
        ids = Array(@record_ids).map { |id| "record_ids[]=#{id}" }
        ids.any? ? "#{page_path}?#{ids.join("&")}" : page_path
      end

      def frame_id
        "#{dialog_id}-frame"
      end

      # Fragment URL the modal's `<turbo-frame>` loads (so the action's `fields` are only
      # evaluated when the modal opens). For non-bulk it's a static `src` the frame loads
      # lazily on open; for bulk the live selection isn't known server-side, so the controller
      # builds the `src` from this base + the checked ids when the modal opens.
      def frame_src_base
        return "#{page_path}?fragment=1&frame_id=#{frame_id}" if @bulk

        sep = action_path.include?("?") ? "&" : "?"
        "#{action_path}#{sep}fragment=1&frame_id=#{frame_id}"
      end

      # The form is loaded lazily inside a `<turbo-frame>` when the modal opens: non-bulk frames
      # have a `src` + `loading="lazy"` (Turbo loads them when the dialog becomes visible); bulk
      # frames get their `src` set by `rua--dialog#open` from the live selection. Without JS the
      # trigger is a link/submit to the full action page, so it still works.
      def render_dialog
        div(data: {rua_dialog: dialog_id}, hidden: true, class: "fixed inset-0 z-50 flex items-center justify-center p-4") do
          div(data: {action: "click->rua--dialog#close"}, class: "absolute inset-0 bg-black/50")

          div(class: "relative z-10 w-full max-w-lg rounded-xl border border-border bg-background shadow-lg") do
            div(class: "flex items-center justify-between p-6 pb-2") do
              h2(class: "text-lg font-semibold") { @action.name }
              button(type: "button", data: {action: "click->rua--dialog#close"}, class: "text-muted-foreground hover:text-foreground") { "✕" }
            end
            div(class: "p-6 pt-2") do
              render_dialog_frame
            end
          end
        end
      end

      def render_dialog_frame
        attrs = {id: frame_id}
        if @bulk
          # No static src — the controller sets it from the checked rows on open.
          attrs[:data] = {rua_frame_base: frame_src_base}
        else
          attrs[:src] = frame_src_base
          attrs[:loading] = "lazy"
        end

        tag(:turbo_frame, **attrs) do
          p(class: "text-sm text-muted-foreground") { "…" }
        end
      end
    end
  end
end
