# frozen_string_literal: true

module RubyUIAdmin
  module Resources
    class Comment < RubyUIAdmin::BaseResource
      self.title = :id
      self.includes = [:post]

      def filters
        filter RubyUIAdmin::Filters::CommentBodyFilter
      end

      def fields
        field :id, as: :id
        field :body, as: :text, link_to_record: true
        field :post, as: :belongs_to
        # record_link: link to the post through the Post resource (computed via a block).
        field :post_link, as: :record_link, use_resource: "Post", only_on: :show do
          record.post
        end
        field :created_at, as: :date_time, only_on: %i[index show]
      end
    end
  end
end
