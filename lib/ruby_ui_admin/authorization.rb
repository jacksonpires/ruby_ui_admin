# frozen_string_literal: true

module RubyUIAdmin
  # Resolves the authorization adapter from `config.authorization_client`. The value may be a
  # symbol (looked up in REGISTRY), a Class (a custom adapter), or nil (disabled — still resolves
  # to the default adapter, which short-circuits to permissive via `authorization_enabled?`).
  module Authorization
    # Symbol → adapter class, wrapped in a lambda so optional backends (Pundit, CanCanCan) are only
    # referenced when actually selected.
    REGISTRY = {
      action_policy: -> { ActionPolicyAdapter },
      pundit: lambda {
        require "ruby_ui_admin/authorization/pundit_adapter"
        PunditAdapter
      },
      cancancan: lambda {
        require "ruby_ui_admin/authorization/can_can_can_adapter"
        CanCanCanAdapter
      }
    }.freeze

    def self.adapter_class(client = RubyUIAdmin.configuration.authorization_client)
      return client if client.is_a?(Class)

      key = (client || :action_policy).to_sym
      resolver = REGISTRY[key]
      unless resolver
        known = REGISTRY.keys.join(", ")
        raise ArgumentError,
          "Unknown authorization_client #{client.inspect}. Use one of: #{known}, an adapter class, or nil."
      end

      resolver.call
    end

    def self.build(...)
      adapter_class.new(...)
    end
  end
end
