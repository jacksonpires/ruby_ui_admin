# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    class StatusFilter < RubyUIAdmin::Filters::SelectFilter
      self.name = "Status"

      def apply(_request, query, value)
        query.where(status: value)
      end

      def options
        {"draft" => "Draft", "published" => "Published", "archived" => "Archived"}
      end
    end
  end
end
