# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Base for has_one / has_many / has_and_belongs_to_many fields. Association
    # fields are shown on the show view only by default.
    class AssociationField < BaseField
      def default_hidden_views
        %i[index new edit]
      end

      # The association read from the record — `for_attribute:` overrides the field id,
      # e.g. `field :discussion, as: :has_many, for_attribute: :comments`.
      def association_name
        options[:for_attribute] || id
      end

      # Read the association (honoring `for_attribute:`); a computed block still wins.
      def value(record, view_context: nil)
        return super if block

        record&.respond_to?(association_name) ? record.public_send(association_name) : nil
      end

      def reflection
        resource&.model_class&.reflect_on_association(association_name)
      end

      def target_model
        options[:model] || reflection&.klass
      end

      # Resource to link associated records through (`use_resource:` overrides the default
      # model→resource lookup done by the view).
      def use_resource
        options[:use_resource]
      end

      # Applies a `scope:` (Symbol naming a relation method, or a lambda with `query`) to a
      # relation value. No-op for nil or no scope.
      def scoped(relation)
        scope = options[:scope]
        return relation if relation.nil? || scope.nil?
        return relation.public_send(scope) if scope.is_a?(Symbol)

        ExecutionContext.new(target: scope, query: relation, resource: resource).handle
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

      # Association values aren't writable through a simple setter here.
      def fill_value(record, value); end
    end
  end
end
