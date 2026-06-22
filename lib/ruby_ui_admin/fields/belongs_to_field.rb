# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class BelongsToField < BaseField
      register_as :belongs_to

      # belongs_to writes/reads the foreign key column.
      def database_id
        :"#{id}_id"
      end

      def foreign_key_value(record)
        record.public_send(database_id) if record&.respond_to?(database_id)
      end

      # The ActiveRecord reflection for this association on the resource model.
      def reflection
        resource&.model_class&.reflect_on_association(id)
      end

      def target_model
        options[:model] || reflection&.klass
      end

      # Candidate records to choose from in forms. Capped to avoid huge selects.
      def options_for_select(limit: 1000)
        model = target_model
        return [] if model.nil?

        model.all.limit(limit).map { |record| [display_label(record), record.id] }
      end

      def display_label(record)
        return nil if record.nil?

        if record.respond_to?(:to_label)
          record.to_label
        elsif record.respond_to?(:name)
          record.name
        elsif record.respond_to?(:title)
          record.title
        else
          "#{record.model_name.human} ##{record.id}"
        end
      end
    end
  end
end
