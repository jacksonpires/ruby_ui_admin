# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    # A filter offering several checkboxes; the submitted value is an Array of the
    # checked option keys. Subclasses define `options` and `apply(request, query, value)`.
    class MultipleSelectFilter < BaseFilter
      register_type :multiple_select
    end
  end
end
