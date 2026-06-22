# frozen_string_literal: true

require "action_policy"

module RubyUIAdmin
  # Base class for admin policies. Host policies (RubyUIAdmin::Policies::*) inherit
  # from this. It lives outside the `RubyUIAdmin::Policies` namespace so Zeitwerk can
  # fully own that namespace for host-defined policies.
  #
  # Migration note: a host's existing base policy maps to this class.
  #
  # `manage?` is action_policy's default rule (fallback for any rule the host policy
  # doesn't define). We defer it to `explicit_authorization`: when explicit_authorization
  # is false, undefined rules are allowed; when true, they are denied.
  class BasePolicy < ActionPolicy::Base
    # `allow_nil: true` so policies can be evaluated with no signed-in user (rules
    # guard with `user&.`); avoids AuthorizationContextMissing in that edge case.
    authorize :user, allow_nil: true
    # The real (non-impersonated) user, for policies that gate on it. Defaults to `user`.
    authorize :true_user, allow_nil: true

    def manage?
      !RubyUIAdmin.configuration.explicit_authorization
    end

    # `index?` and `create?` are concretely defined as `false` by action_policy's
    # Defaults module, so redirect them to the same fallback as every other rule.
    def index? = manage?

    def create? = manage?

    # NOTE: no default `relation_scope` is declared here on purpose. The Rails
    # `relation_scope` alias is only registered after the action_policy railtie
    # loads (post-boot), whereas this base class is required at gem load time.
    # When a host policy defines no scope, AuthorizationService#apply_policy
    # rescues the UnknownScope error and returns the relation untouched.
  end
end
