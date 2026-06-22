# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    # Multiple-select filter: `value` is an Array of the checked status keys.
    class StatusesFilter < RubyUIAdmin::Filters::MultipleSelectFilter
      self.name = "Statuses"

      def options
        {"draft" => "Draft", "published" => "Published", "archived" => "Archived"}
      end

      def apply(_request, query, value)
        query.where(status: Array(value))
      end
    end
  end
end
