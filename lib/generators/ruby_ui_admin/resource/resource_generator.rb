# frozen_string_literal: true

require "rails/generators/named_base"

module RubyUIAdmin
  module Generators
    class ResourceGenerator < Rails::Generators::NamedBase
      namespace "ruby_ui_admin:resource"
      source_root File.expand_path("templates", __dir__)

      desc "Generates a RubyUI Admin resource (with fields derived from the model)."

      class_option :model_class, type: :string, desc: "Override the inferred model class name"

      def create_resource
        template "resource.rb.tt", File.join("app/ruby_ui_admin/resources", "#{singular_name}.rb")
      end

      private

      def resource_class_name
        class_name.demodulize
      end

      def model_class_name
        options[:model_class]
      end

      def model_klass
        (model_class_name || class_name).safe_constantize
      end

      # Builds the body of `def fields`, one `field ...` line per column/association.
      def fields_block
        indent = "        "
        lines = ["#{indent}field :id, as: :id"]

        if (model = model_klass)
          model.columns.each do |column|
            next if column.name == "id" || column.name.end_with?("_id")

            type = column_field_type(column)
            # Keep the index lean: long-form fields (textarea/code) are noisy in a table, so show
            # them only on the record's show/new/edit pages by default. Tweak or drop `only_on:`.
            suffix = hidden_from_index?(type) ? ", only_on: %i[show new edit]" : ""
            lines << "#{indent}field :#{column.name}, as: :#{type}#{suffix}"
          end

          model.reflect_on_all_associations.each do |association|
            type = association_field_type(association)
            lines << "#{indent}field :#{association.name}, as: :#{type}" if type
          end
        end

        lines.join("\n")
      rescue
        "        field :id, as: :id"
      end

      def column_field_type(column)
        return :password if column.name.match?(/password/)
        return :text if column.name == "email"

        {
          string: :text, text: :textarea, integer: :number, float: :number,
          decimal: :number, boolean: :boolean, date: :date, datetime: :date_time,
          timestamp: :date_time, json: :code, jsonb: :code
        }.fetch(column.type, :text)
      end

      # Long-form field types are hidden from the index by default (still on show/new/edit).
      def hidden_from_index?(type)
        %i[textarea code].include?(type)
      end

      def association_field_type(association)
        {
          belongs_to: :belongs_to, has_one: :has_one,
          has_many: :has_many, has_and_belongs_to_many: :has_and_belongs_to_many
        }[association.macro]
      end
    end
  end
end
