# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    # Hash-based boolean filter: `options` define several checkboxes and `value` is a hash
    # of `{ key => "true"/"false" }`.
    class VisibilityFilter < RubyUIAdmin::Filters::BooleanFilter
      self.name = "Visibility"

      def options
        {"published" => "Published", "unpublished" => "Unpublished"}
      end

      def apply(_request, query, value)
        states = []
        states << true if value["published"] == "true"
        states << false if value["unpublished"] == "true"
        return query if states.empty?

        query.where(published: states)
      end
    end
  end
end
