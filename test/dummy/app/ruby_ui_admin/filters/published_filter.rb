# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    class PublishedFilter < RubyUIAdmin::Filters::BooleanFilter
      self.name = "Published"

      def apply(_request, query, value)
        query.where(published: value == "true")
      end
    end
  end
end
