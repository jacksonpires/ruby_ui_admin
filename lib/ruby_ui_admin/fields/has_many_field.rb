# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class HasManyField < AssociationField
      register_as :has_many

      # Capped collection of associated records for display on the show view.
      def associated_records(record, limit: 25)
        collection = scoped(value(record))
        return [] if collection.nil?

        collection.respond_to?(:limit) ? collection.limit(limit) : Array(collection).first(limit)
      end

      def count(record)
        collection = scoped(value(record))
        return 0 if collection.nil?

        collection.respond_to?(:count) ? collection.count : Array(collection).size
      end
    end
  end
end
