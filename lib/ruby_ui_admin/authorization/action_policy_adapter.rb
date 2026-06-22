# frozen_string_literal: true

require "action_policy"

module RubyUIAdmin
  module Authorization
    # action_policy-backed adapter (the default). Bridges the admin's authorization onto
    # action_policy: `allowed_to?`, `authorized_scope`, `policy_for`. Rules the policy doesn't
    # define fall back to its default rule (`manage?`), which `RubyUIAdmin::BasePolicy` ties to
    # `explicit_authorization`; a missing policy is decided by `explicit_authorization` too.
    class ActionPolicyAdapter < Adapter
      include ActionPolicy::Behaviour

      # Declares the authorization context required by policies (resolved via the readers on Adapter).
      authorize :user
      authorize :true_user

      def authorize_action(rule, record: nil, raise_exception: true)
        return true unless RubyUIAdmin.configuration.authorization_enabled?

        target = record.nil? ? @record : record
        normalized = normalize_rule(rule)

        begin
          result = allowed_to?(normalized, target, with: policy_class)
        rescue ActionPolicy::NotFound
          return handle_missing_policy(raise_exception)
        end

        if !result && raise_exception
          raise NotAuthorizedError, "Not authorized to #{normalized} on #{target.inspect}"
        end

        result
      end

      def apply_policy(scope)
        return scope unless RubyUIAdmin.configuration.authorization_enabled?

        authorized_scope(scope, with: policy_class)
      rescue ActionPolicy::UnknownScopeType,
             ActionPolicy::UnknownNamedScope,
             ActionPolicy::UnrecognizedScopeTarget,
             ActionPolicy::NotFound
        scope
      end

      def has_rule?(rule, record: nil)
        target = record.nil? ? @record : record
        policy = policy_for(record: target, with: policy_class, allow_nil: true)
        return false if policy.nil?

        policy.respond_to?(normalize_rule(rule))
      rescue ActionPolicy::NotFound
        false
      end

      # Whether the policy CLASS explicitly defines this rule as a public method (i.e. not satisfied
      # only by the `manage?` default). Used for field-level authorization.
      def defines_rule?(rule)
        return false if policy_class.nil?

        policy_class.public_method_defined?(normalize_rule(rule))
      rescue
        false
      end
    end
  end
end
