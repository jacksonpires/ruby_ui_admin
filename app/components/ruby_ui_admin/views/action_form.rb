# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # The inner form of a custom action (message + fields + buttons). Shared by the
    # action page (Views::Action) and the inline action dialog (Views::ActionTrigger).
    class ActionForm < Phlex::HTML
      include RubyUIAdmin::UI
      include RailsHelpers
      include PathHelpers

      def initialize(resource:, action:, action_id:, record_ids: [], frame_id: nil)
        @resource = resource
        @action = action
        @action_id = action_id
        @record_ids = record_ids
        @frame_id = frame_id
      end

      # When loaded into the modal's `<turbo-frame>`, wrap the form in the matching frame so
      # Turbo swaps it in. `data-turbo-frame="_top"` makes the submit break out into a full
      # visit (POST→303→redirect+flash) instead of just reloading the frame. On the standalone
      # action page (no frame_id) the form renders bare and `_top` is a harmless no-op.
      def view_template
        if @frame_id
          tag(:turbo_frame, id: @frame_id) { render_form }
        else
          render_form
        end
      end

      def render_form
        form(action: action_path, method: "post", enctype: form_enctype, class: "space-y-5", data: {turbo_frame: "_top"}) do
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          record_id_fields
          render_message
          @action.get_fields.each { |field| render_field(field) }
          render_actions
        end
      end

      private

      def action_path
        ruby_ui_admin.resource_action_path(resource_name: @resource.route_key, action_id: @action_id)
      end

      # File-upload fields require a multipart form.
      def form_enctype
        @action.get_fields.any? { |field| %i[file files].include?(field.type) } ? "multipart/form-data" : nil
      end

      def record_id_fields
        Array(@record_ids).each do |id|
          input(type: "hidden", name: "record_ids[]", value: id)
        end
      end

      def render_message
        message = @action.message
        return if message.blank?

        div(class: "text-sm text-muted-foreground") { raw(safe(message.to_s)) }
      end

      def render_field(field)
        # A lone checkbox reads as "[ ] Label" — render it inline beside the label.
        if field.type == :boolean
          div(class: "space-y-1.5") do
            label(class: "flex items-center gap-2 text-sm font-medium leading-none") do
              render RubyUIAdmin::Views::FieldInput.new(field: field, record: nil, name_prefix: "fields")
              plain field.name
              span(class: "text-destructive ml-0.5") { "*" } if field.required?
            end
          end
          return
        end

        div(class: "space-y-1.5") do
          label(class: "text-sm font-medium leading-none") do
            plain field.name
            span(class: "text-destructive ml-0.5") { "*" } if field.required?
          end
          render RubyUIAdmin::Views::FieldInput.new(field: field, record: nil, name_prefix: "fields")
        end
      end

      def render_actions
        div(class: "flex items-center gap-3 pt-2") do
          render(RubyUI::Button.new(type: :submit, variant: :primary)) { @action.class.confirm_button_label }

          # Closes the dialog when inside one (Stimulus preventDefaults); otherwise falls back to
          # the index. `_top` ensures any non-prevented click escapes the frame (a full visit)
          # rather than rendering the index inside the modal frame.
          a(
            href: resource_index_path(@resource.class),
            data: {action: "click->rua--dialog#close", turbo_frame: "_top"},
            class: "text-sm text-muted-foreground hover:underline"
          ) { @action.class.cancel_button_label }
        end
      end
    end
  end
end
