# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    class HasOneField < AssociationField
      register_as :has_one

      def associated_record(record)
        value(record)
      end
    end
  end
end
