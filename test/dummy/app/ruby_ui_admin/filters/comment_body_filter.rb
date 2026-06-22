# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    # Has a `default`, applied on the Comment index when no filter is submitted.
    class CommentBodyFilter < RubyUIAdmin::Filters::TextFilter
      self.name = "Body contains"

      def default
        "keep"
      end

      def apply(_request, query, value)
        query.where("body LIKE ?", "%#{value}%")
      end
    end
  end
end
