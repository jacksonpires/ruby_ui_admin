# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Renders a show field as a label/value row. Shared by the full Show view and the lazy
    # tab fragment (ShowTab) so both render fields identically. Expects `@record` to be set.
    module ShowFields
      # Called by StructureRenderer for each field.
      def render_field(field)
        render_field_row(field)
      end

      def render_field_row(field)
        # Collection associations render as a full-width table, so the label goes above it
        # (a left label column would squeeze the table into a third of the width).
        return render_association_row(field) if %i[has_many has_and_belongs_to_many].include?(field.type)

        div(class: "grid grid-cols-3 gap-4 py-3 border-b border-border last:border-b-0") do
          dt(class: "text-sm font-medium text-muted-foreground", title: field.description) { field.name }
          dd(class: "text-sm col-span-2") do
            render RubyUIAdmin::Views::FieldValue.new(field: field, record: @record)
          end
        end
      end

      def render_association_row(field)
        div(class: "py-3 space-y-2 border-b border-border last:border-b-0") do
          div do
            span(class: "text-sm font-medium text-muted-foreground") { field.name }
            p(class: "text-xs text-muted-foreground") { field.description } if field.description
          end
          render RubyUIAdmin::Views::FieldValue.new(field: field, record: @record)
        end
      end
    end
  end
end
