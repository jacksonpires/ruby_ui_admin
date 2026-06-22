# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class SelectField < BaseField
      register_as :select

      # Resolves the configured options into an array of [label, value] pairs.
      # `options:` accepts an Array, a Hash ({value => label}), or a lambda.
      # `enum:` derives options from an ActiveRecord enum: pass the enum mapping
      # (`enum: Post.statuses`) or `enum: true` to read `model_class.<id.pluralize>`.
      def select_options(record = nil)
        return enum_options if enum_options

        raw = options[:options]
        if raw.respond_to?(:call)
          # The options lambda can use `record`/`resource` plus `params`/`view` (e.g. an
          # options list that depends on the request, like a nested-create parent id).
          raw = ExecutionContext.new(
            target: raw,
            record: record,
            resource: resource,
            params: resource&.params,
            view: View.wrap(resource&.view)
          ).handle
        end

        pairs =
          case raw
          when Hash then raw.map { |value, label| [label, value] }
          when Array then raw.map { |entry| entry.is_a?(Array) ? entry : [entry, entry] }
          else []
          end

        # `display_with_value: true` -> option labels become "Label (value)".
        return pairs.map { |(label, value)| ["#{label} (#{value})", value] } if options[:display_with_value]

        pairs
      end

      def include_blank?
        options.fetch(:include_blank, !required?)
      end

      # `[label, value]` pairs derived from an ActiveRecord enum, or nil when no `enum:`.
      def enum_options
        enum = options[:enum]
        return nil if enum.nil? || enum == false

        mapping =
          if enum == true
            resource&.model_class&.public_send(id.to_s.pluralize)
          else
            enum
          end
        return nil unless mapping.respond_to?(:keys)

        mapping.keys.map { |key| [key.to_s.humanize, key.to_s] }
      end

      # Display label for the current value.
      def formatted_value(record, view_context: nil)
        raw = value(record, view_context: view_context)
        return super if @format_using

        pair = select_options(record).find { |(_label, val)| val.to_s == raw.to_s }
        pair ? pair.first : raw
      end
    end
  end
end
