# frozen_string_literal: true

require "json"

module RubyUIAdmin
  module Fields
    # Edits a Hash value. Displayed as a key/value table; edited as JSON in a textarea.
    class KeyValueField < BaseField
      register_as :key_value

      def default_hidden_views
        %i[index]
      end

      def value_as_json(record)
        raw = value(record)
        return "{}" if raw.blank?

        JSON.pretty_generate(raw)
      rescue
        raw.to_s
      end

      # Parse the submitted JSON back into a Hash before assigning.
      def fill_value(record, value)
        parsed =
          if value.is_a?(String) && value.present?
            begin
              JSON.parse(value)
            rescue JSON::ParserError
              value
            end
          else
            value
          end

        super(record, parsed)
      end
    end
  end
end
