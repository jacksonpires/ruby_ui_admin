# frozen_string_literal: true

module RubyUIAdmin
  module Services
    # Facade over the configured authorization adapter (`config.authorization_client`, default
    # action_policy). Resolves the adapter and delegates, so controllers/views/resources stay
    # backend-agnostic. The backend logic lives in `RubyUIAdmin::Authorization::*Adapter`.
    class AuthorizationService
      def initialize(user, record = nil, policy_class: nil, true_user: nil)
        @adapter = RubyUIAdmin::Authorization.build(user, record, policy_class: policy_class, true_user: true_user)
      end

      def authorize_action(rule, record: nil, raise_exception: true)
        @adapter.authorize_action(rule, record: record, raise_exception: raise_exception)
      end

      def allowed?(rule, record: nil) = @adapter.allowed?(rule, record: record)

      def apply_policy(scope) = @adapter.apply_policy(scope)

      def has_rule?(rule, record: nil) = @adapter.has_rule?(rule, record: record)

      def defines_rule?(rule) = @adapter.defines_rule?(rule)

      def true_user = @adapter.true_user

      def set_record(record)
        @adapter.set_record(record)
        self
      end

      # Context readers (kept for backward compatibility with any caller reading them).
      def user = @adapter.user
      def record = @adapter.record
      def policy_class = @adapter.policy_class
    end
  end
end
