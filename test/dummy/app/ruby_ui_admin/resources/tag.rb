# frozen_string_literal: true

module RubyUIAdmin
  module Resources
    class Tag < RubyUIAdmin::BaseResource
      self.title = :name
      # Demonstrates countless pagination (no COUNT query) for a potentially large table.
      self.countless = true

      def fields
        field :id, as: :id
        field :name, as: :text, link_to_record: true, sortable: true
        field :users, as: :has_and_belongs_to_many
      end
    end
  end
end
