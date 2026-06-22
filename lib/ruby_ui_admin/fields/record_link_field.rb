# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Renders a link to another record, resolved through a named resource:
    #   field :detail, as: :record_link, use_resource: "FormGroup", only_on: :show
    class RecordLinkField < BaseField
      register_as :record_link

      def default_hidden_views
        %i[new edit]
      end

      def use_resource
        options[:use_resource]
      end

      def linked_record(record)
        value(record)
      end

      def display_label(record)
        return nil if record.nil?

        if record.respond_to?(:to_label) then record.to_label
        elsif record.respond_to?(:name) then record.name
        elsif record.respond_to?(:title) then record.title
        else "#{record.model_name.human} ##{record.id}"
        end
      end

      # The resource class used to build the link.
      def target_resource(linked = nil)
        if use_resource
          RubyUIAdmin.resource_manager.resources.find { |r| r.name.to_s.demodulize == use_resource.to_s } ||
            (Object.const_get("RubyUIAdmin::Resources::#{use_resource}") rescue nil)
        elsif linked
          RubyUIAdmin.resource_manager.find_for_model(linked.class)
        end
      end

      def fill_value(record, value); end
    end
  end
end
