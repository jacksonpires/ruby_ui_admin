# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Registry mapping a DSL symbol (`as: :text`) to a field class.
    # Each field subclass registers itself via `register_as`.
    @mapping = {}

    class << self
      attr_reader :mapping

      def register(key, klass)
        @mapping[key.to_sym] = klass
      end

      def field_class_for(key)
        @mapping.fetch(key.to_sym) do
          raise ArgumentError, "Unknown field type :#{key}. Registered: #{@mapping.keys.join(", ")}"
        end
      end

      def registered?(key)
        @mapping.key?(key.to_sym)
      end
    end
  end
end
