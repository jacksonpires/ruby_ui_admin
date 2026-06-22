# frozen_string_literal: true

module RubyUIAdmin
  module Authorization
    # Interface every authorization adapter implements. `Services::AuthorizationService` resolves the
    # configured adapter (`config.authorization_client`) and delegates to it, so call sites stay
    # backend-agnostic. An adapter bridges the admin's rule vocabulary (`index?`/`show?`/`update?`/
    # `destroy?`/`act_on?`/`view_<field>?`, with the `manage?` + `explicit_authorization` fallback)
    # onto a backend (action_policy, Pundit, CanCanCan, …).
    #
    # Subclasses must implement: #authorize_action, #apply_policy, #has_rule?, #defines_rule?.
    # The shared context (#user, #true_user, #record, #policy_class), #allowed? and #normalize_rule
    # live here.
    class Adapter
      attr_reader :user, :record, :policy_class

      def initialize(user, record = nil, policy_class: nil, true_user: nil)
        @user = user
        @record = record
        @policy_class = policy_class
        @true_user = true_user
      end

      # The real (impersonating) user. Defaults to `Current.true_user`, falling back to `user`.
      def true_user
        @true_user || RubyUIAdmin::Current.true_user || @user
      end

      def set_record(record)
        @record = record
        self
      end

      # Authorizes a single rule. Returns a boolean; raises `NotAuthorizedError` when denied and
      # `raise_exception` is true.
      def authorize_action(_rule, record: nil, raise_exception: true)
        raise NotImplementedError, "#{self.class} must implement #authorize_action"
      end

      def allowed?(rule, record: nil)
        authorize_action(rule, record: record, raise_exception: false)
      end

      # Applies the policy's record scope to a relation; returns it unchanged when none applies.
      def apply_policy(_scope)
        raise NotImplementedError, "#{self.class} must implement #apply_policy"
      end

      # Whether the resolved policy/instance responds to the rule (for the given record).
      def has_rule?(_rule, record: nil)
        raise NotImplementedError, "#{self.class} must implement #has_rule?"
      end

      # Whether the policy CLASS explicitly defines the rule (field-level auth: an undefined rule
      # means "no opinion" → the field stays visible).
      def defines_rule?(_rule)
        raise NotImplementedError, "#{self.class} must implement #defines_rule?"
      end

      private

      def normalize_rule(rule)
        string = rule.to_s
        string.end_with?("?") ? string.to_sym : :"#{string}?"
      end

      # Shared "no policy / undefined rule" fallback: `explicit_authorization` decides — denied when
      # true (raising if requested), allowed when false. Used by every adapter so the
      # missing-policy/undefined-rule semantics stay identical across backends.
      def handle_missing_policy(raise_exception)
        if RubyUIAdmin.configuration.explicit_authorization
          raise NotAuthorizedError, "No policy found" if raise_exception
          false
        else
          true
        end
      end
    end
  end
end
