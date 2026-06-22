# frozen_string_literal: true

module RubyUIAdmin
  module Scopes
    # Base class for named index scopes. A scope narrows the index query
    # via a `scope` lambda and shows up as a tab above the table.
    #
    #   class Published < RubyUIAdmin::Scopes::BaseScope
    #     self.name = "Published"
    #     self.scope = -> { query.where(published: true) }
    #     self.default = true
    #   end
    class BaseScope
      class << self
        # Class-level `self.name =` with fallback to the real class name.
        def name=(value)
          @display_name = value
        end

        def name
          @display_name || super
        end

        def scope=(value)
          @scope = value
        end

        def scope
          @scope if defined?(@scope)
        end

        def description=(value)
          @description = value
        end

        def description
          @description if defined?(@description)
        end

        def default=(value)
          @default = value
        end

        def default?
          !!(@default if defined?(@default))
        end

        def visible=(value)
          @visible = value
        end

        def visible_setting
          defined?(@visible) ? @visible : true
        end

        # URL key, e.g. RubyUIAdmin::Scopes::PublishedPosts -> "published_posts".
        def scope_key
          to_s.sub(/^RubyUIAdmin::Scopes::/, "").gsub("::", "_").underscore
        end
      end

      attr_reader :params

      # `default_override` (set via `scope Klass, default: true` on the resource) wins over
      # the scope class's own `self.default`.
      def initialize(params: {}, default_override: nil)
        @params = params || {}
        @default_override = default_override
      end

      def name
        self.class.name
      end

      def key
        self.class.scope_key
      end

      def description
        self.class.description
      end

      def default?
        return !!@default_override unless @default_override.nil?

        self.class.default?
      end

      # Applies the scope to the query. A Symbol calls the model's named scope/class method;
      # a lambda is run with `query` and `params` available.
      def apply(query)
        scope = self.class.scope
        return query if scope.nil?
        return query.public_send(scope) if scope.is_a?(Symbol)

        ExecutionContext.new(target: scope, query: query, params: params).handle
      end

      def visible?(user: nil)
        setting = self.class.visible_setting
        return setting unless setting.respond_to?(:call)

        ExecutionContext.new(target: setting, user: user, params: params).handle
      end
    end
  end
end
