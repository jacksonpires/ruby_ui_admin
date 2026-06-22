# frozen_string_literal: true

begin
  require "pundit"
rescue LoadError
  raise LoadError, "config.authorization_client = :pundit requires the `pundit` gem. Add `gem \"pundit\"` to your Gemfile."
end

module RubyUIAdmin
  module Authorization
    # Pundit-backed adapter. Maps the admin's rules onto a Pundit policy (`policy.show?`), record
    # scopes onto the policy's `Scope`, and uses `respond_to?`/`public_method_defined?` for the
    # field-level "is this rule defined?" check. A rule the policy doesn't define (or a missing
    # policy) falls back to `explicit_authorization`, keeping the same semantics as action_policy.
    #
    # The resource's `authorization_policy` is used as the policy class when given; otherwise Pundit
    # infers it (`Pundit::PolicyFinder`). Pundit policies receive only `user` — `true_user`
    # (impersonation) is not passed to them.
    class PunditAdapter < Adapter
      def authorize_action(rule, record: nil, raise_exception: true)
        return true unless RubyUIAdmin.configuration.authorization_enabled?

        target = record.nil? ? @record : record
        policy = policy_instance(target)
        normalized = normalize_rule(rule)

        return handle_missing_policy(raise_exception) if policy.nil? || !policy.respond_to?(normalized)

        result = !!policy.public_send(normalized)
        if !result && raise_exception
          raise NotAuthorizedError, "Not authorized to #{normalized} on #{target.inspect}"
        end

        result
      end

      def apply_policy(scope)
        return scope unless RubyUIAdmin.configuration.authorization_enabled?

        scope_class = scope_class_for(scope)
        return scope unless scope_class

        scope_class.new(user, scope).resolve
      rescue Pundit::NotDefinedError
        scope
      end

      def has_rule?(rule, record: nil)
        target = record.nil? ? @record : record
        policy = policy_instance(target)
        return false if policy.nil?

        policy.respond_to?(normalize_rule(rule))
      end

      def defines_rule?(rule)
        return false if policy_class.nil?

        policy_class.public_method_defined?(normalize_rule(rule))
      rescue
        false
      end

      private

      # Explicit `authorization_policy` wins; otherwise Pundit infers the policy class from the
      # target (instance or class). Returns nil when none can be resolved.
      def policy_instance(target)
        klass = policy_class || Pundit::PolicyFinder.new(target).policy
        return nil unless klass

        klass.new(user, target)
      rescue Pundit::NotDefinedError
        nil
      end

      def scope_class_for(scope)
        if policy_class&.const_defined?(:Scope)
          policy_class::Scope
        else
          Pundit::PolicyFinder.new(scope).scope
        end
      end
    end
  end
end
