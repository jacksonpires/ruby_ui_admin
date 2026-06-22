# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    class TitleFilter < RubyUIAdmin::Filters::TextFilter
      self.name = "Title"

      def apply(_request, query, value)
        query.where("title LIKE ?", "%#{value}%")
      end
    end
  end
end
