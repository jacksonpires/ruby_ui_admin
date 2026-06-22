# frozen_string_literal: true

module RubyUIAdmin
  module Views
    class Form < Base
      include StructureRenderer

      def initialize(resource:, record:, view:)
        @resource = resource
        @record = record
        @view = view.to_sym
      end

      def page_title
        "#{title_prefix} · #{RubyUIAdmin.configuration.app_name}"
      end

      def content
        render_header
        render_errors_summary

        form(action: form_action, method: "post", enctype: form_enctype, class: "space-y-6") do
          hidden_method_field
          csrf_field

          render_structure(@resource.field_structure(view: @view))

          render_actions
        end
      end

      private

      # File-upload fields require a multipart form.
      def form_enctype
        @resource.get_fields(view: @view).any? { |f| %i[file files].include?(f.type) } ? "multipart/form-data" : nil
      end

      def new_record?
        @view == :new
      end

      def title_prefix
        new_record? ? "New #{@resource.model_class.model_name.human}" : "Edit #{@resource.record_title(@record)}"
      end

      def form_action
        if new_record?
          resource_index_path(@resource.class)
        else
          resource_show_path(@resource.class, @record)
        end
      end

      def render_header
        div(class: "mb-6") do
          a(href: resource_index_path(@resource.class), class: "text-sm text-muted-foreground hover:underline") { "← #{@resource.navigation_label}" }
          h1(class: "text-2xl font-semibold tracking-tight mt-1") { title_prefix }
        end
      end

      def render_errors_summary
        return unless @record.errors.any?

        div(class: "mb-4 rounded-md border border-destructive/30 bg-destructive/5 p-4") do
          p(class: "text-sm font-medium text-destructive mb-1") { rua_t("form.errors") }
          ul(class: "list-disc list-inside text-sm text-destructive") do
            @record.errors.full_messages.each { |message| li { message } }
          end
        end
      end

      def render_field(field)
        # Hidden fields carry a value with no visible label/row.
        if field.type == :hidden
          render RubyUIAdmin::Views::FieldInput.new(field: field, record: @record)
          return
        end

        # A lone checkbox reads as "[ ] Label" — render it inline beside the label
        # instead of stacking (which would leave the checkbox glued to the label text).
        return render_boolean_field(field) if field.type == :boolean && !field.readonly?

        div(class: "space-y-1.5 w-full md:w-8/12") do
          label(class: "text-sm font-medium leading-none", title: field.description) do
            plain field.name
            span(class: "text-destructive ml-0.5") { "*" } if field.required?
          end

          if field.readonly?
            div(class: "text-sm text-muted-foreground") do
              render RubyUIAdmin::Views::FieldValue.new(field: field, record: @record)
            end
          else
            render RubyUIAdmin::Views::FieldInput.new(field: field, record: @record)
          end

          if (help = field.help)
            p(class: "text-xs text-muted-foreground") { help }
          end

          field_errors(field)
        end
      end

      def render_boolean_field(field)
        div(class: "space-y-1.5 w-full md:w-8/12") do
          label(class: "flex items-center gap-2 text-sm font-medium leading-none", title: field.description) do
            render RubyUIAdmin::Views::FieldInput.new(field: field, record: @record)
            plain field.name
            span(class: "text-destructive ml-0.5") { "*" } if field.required?
          end

          if (help = field.help)
            p(class: "text-xs text-muted-foreground") { help }
          end

          field_errors(field)
        end
      end

      def field_errors(field)
        messages = @record.errors[field.database_id]
        return if messages.blank?

        p(class: "text-xs text-destructive") { messages.join(", ") }
      end

      def render_actions
        div(class: "flex items-center gap-3 pt-2") do
          button(
            type: "submit",
            class: "inline-flex items-center h-9 px-4 rounded-md bg-primary text-primary-foreground text-sm font-medium shadow hover:bg-primary/90"
          ) { new_record? ? rua_t("actions.create") : rua_t("actions.update") }

          a(href: resource_index_path(@resource.class), class: "text-sm text-muted-foreground hover:underline") { rua_t("actions.cancel") }
        end
      end

      def hidden_method_field
        return if new_record?

        input(type: "hidden", name: "_method", value: "patch")
      end

      def csrf_field
        input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
      end
    end
  end
end
