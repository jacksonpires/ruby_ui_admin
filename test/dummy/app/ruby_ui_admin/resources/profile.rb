# frozen_string_literal: true

module RubyUIAdmin
  module Resources
    class Profile < RubyUIAdmin::BaseResource
      self.title = :headline
      self.includes = [:user]

      def fields
        field :id, as: :id
        field :headline, as: :text, link_to_record: true
        field :bio, as: :textarea, only_on: %i[show new edit]
        field :user, as: :belongs_to
        field :created_at, as: :date_time, only_on: %i[index show]
      end
    end
  end
end
