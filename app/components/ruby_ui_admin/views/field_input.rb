# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Renders a form input for a field, dispatching on the field type.
    class FieldInput < Phlex::HTML
      include RubyUIAdmin::UI
      include Translation

      def initialize(field:, record:, name_prefix: "record")
        @field = field
        @record = record
        @name_prefix = name_prefix
      end

      def view_template
        case @field.type
        when :boolean then render_boolean
        when :number then render_number
        when :date then render_date
        when :date_time then render_date_time
        when :textarea then render_textarea
        when :code then render_code
        when :key_value then render_key_value
        when :select then render_select
        when :url then render_url
        when :hidden then render_hidden
        when :password then render_password
        when :boolean_group then render_boolean_group
        when :belongs_to then render_belongs_to
        when :file then render_file
        when :files then render_files
        else render_text
        end
      end

      private

      def input_name
        "#{@name_prefix}[#{@field.permitted_param}]"
      end

      def render_text
        render RubyUI::Input.new(type: :text, name: input_name, value: @field.value(@record), placeholder: @field.placeholder)
      end

      def render_number
        render RubyUI::Input.new(type: :number, name: input_name, value: @field.value(@record))
      end

      def render_url
        render RubyUI::Input.new(type: :url, name: input_name, value: @field.value(@record), placeholder: @field.placeholder)
      end

      def render_password
        render RubyUI::Input.new(type: :password, name: input_name, autocomplete: "new-password")
      end

      def render_hidden
        input(type: :hidden, name: input_name, value: @field.value(@record))
      end

      def render_date
        value = @field.value(@record)
        formatted = value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d") : value
        render RubyUI::Input.new(type: :date, name: input_name, value: formatted)
      end

      def render_date_time
        value = @field.value(@record)
        formatted = value.respond_to?(:strftime) ? value.strftime("%Y-%m-%dT%H:%M") : value
        render RubyUI::Input.new(type: "datetime-local", name: input_name, value: formatted)
      end

      def render_textarea
        render RubyUI::Textarea.new(name: input_name, rows: @field.rows) { @field.value(@record).to_s }
      end

      def render_code
        render RubyUI::Textarea.new(name: input_name, rows: 8, class: "font-mono") { @field.value(@record).to_s }
      end

      def render_key_value
        render RubyUI::Textarea.new(name: input_name, rows: 6, class: "font-mono") { @field.value_as_json(@record) }
      end

      def render_boolean
        input(type: :hidden, name: input_name, value: "0")
        render RubyUI::Checkbox.new(name: input_name, value: "1", checked: !!@field.value(@record))
      end

      def render_boolean_group
        div(class: "flex flex-col gap-2") do
          @field.group_options.each do |key, label_text|
            option_name = "#{input_name}[#{key}]"
            label(class: "flex items-center gap-2 text-sm") do
              # Paired hidden "0" so unchecked boxes are submitted (and persisted as false).
              input(type: :hidden, name: option_name, value: "0")
              render RubyUI::Checkbox.new(name: option_name, value: "1", checked: @field.checked?(@record, key))
              plain label_text
            end
          end
        end
      end

      def render_select
        render RubyUIAdmin::UI::Select.new(
          name: input_name,
          options: @field.select_options(@record),
          selected: @field.value(@record),
          include_blank: @field.include_blank?
        )
      end

      def render_belongs_to
        render RubyUIAdmin::UI::Select.new(
          name: input_name,
          options: @field.options_for_select,
          selected: @field.foreign_key_value(@record),
          include_blank: true
        )
      end

      def render_file
        div(class: "space-y-2") do
          if @field.respond_to?(:attached?) && @field.attached?(@record)
            blob = @field.attachment(@record).blob
            div(class: "flex items-center gap-2 text-sm text-muted-foreground") do
              render RubyUIAdmin::UI::Icon.new(:file, class: "size-4 shrink-0")
              span { blob.filename.to_s }
            end
            label(class: "flex items-center gap-2 text-sm text-muted-foreground") do
              render RubyUI::Checkbox.new(name: "#{@name_prefix}[#{@field.remove_param}]", value: "1")
              plain rua_t("fields.file.remove")
            end
          end
          render RubyUI::Input.new(type: :file, name: input_name, accept: @field.accept)
        end
      end

      def render_files
        div(class: "space-y-2") do
          @field.attachments(@record).each do |att|
            label(class: "flex items-center gap-2 text-sm text-muted-foreground") do
              render RubyUI::Checkbox.new(name: "#{@name_prefix}[#{@field.remove_ids_param}][]", value: att.id.to_s)
              render RubyUIAdmin::UI::Icon.new(:file, class: "size-4 shrink-0")
              span { att.blob.filename.to_s }
            end
          end
          # New uploads are appended (not replacing the existing ones); check a box above to remove.
          render RubyUI::Input.new(type: :file, name: "#{input_name}[]", accept: @field.accept, multiple: true)
        end
      end
    end
  end
end
