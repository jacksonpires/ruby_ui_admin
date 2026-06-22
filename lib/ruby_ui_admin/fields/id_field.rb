# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class IdField < BaseField
      register_as :id

      def initialize(id = :id, **options, &block)
        super
        @link_to_record = options.fetch(:link_to_record, true)
      end

      # The id isn't editable, so keep it off the new/edit forms.
      def default_hidden_views
        %i[new edit]
      end
    end
  end
end
