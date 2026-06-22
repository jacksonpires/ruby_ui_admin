# frozen_string_literal: true

module RubyUIAdmin
  module Filters
    # Base class for filters. Subclasses implement `apply(request, query, value)`
    # and (for select-style filters) `options`.
    class BaseFilter
      class << self
        # Class-level `self.name =` while still falling back to the real class
        # name (so Zeitwerk/Rails keep working when no display name is set).
        def name=(value)
          @display_name = value
        end

        def name
          @display_name || super
        end

        def empty_message=(value)
          @empty_message = value
        end

        def empty_message
          defined?(@empty_message) ? @empty_message : nil
        end

        # Inherited down the chain (subclasses of SelectFilter are :select, etc.).
        def filter_type
          return @filter_type if defined?(@filter_type) && @filter_type
          return superclass.filter_type if superclass.respond_to?(:filter_type)

          nil
        end

        def register_type(type)
          @filter_type = type.to_sym
        end
      end

      attr_reader :arguments

      def initialize(arguments: {})
        @arguments = arguments || {}
      end

      def name
        self.class.name
      end

      def type
        self.class.filter_type
      end

      def empty_message
        self.class.empty_message
      end

      # Unique key used in the query string, e.g.
      # RubyUIAdmin::Filters::PublishedFilter -> "published_filter".
      # Uses `to_s` (not the overridable `name`) to get the real class name.
      def param_key
        self.class.to_s.sub(/^RubyUIAdmin::Filters::/, "").gsub("::", "_").underscore
      end

      # Override in subclasses.
      def apply(request, query, value)
        query
      end

      # Override in select/multiple-select filters.
      def options
        {}
      end

      # Override to provide a default selected value.
      def default
        nil
      end
    end
  end
end
