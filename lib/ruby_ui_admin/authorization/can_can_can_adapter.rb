# frozen_string_literal: true

begin
  require "cancancan"
rescue LoadError
  raise LoadError, "config.authorization_client = :cancancan requires the `cancancan` gem. Add `gem \"cancancan\"` to your Gemfile."
end

module RubyUIAdmin
  module Authorization
    # CanCanCan-backed adapter. Maps the admin's CRUD rules onto `Ability#can?(action, subject)` and
    # the index scope onto `relation.accessible_by(ability)`.
    #
    # ⚠️ PARTIAL by design (CanCanCan is action/subject-based, not policy-class-based):
    #   * No `policy_class` — a single global Ability (`config.cancancan_ability_class`, default
    #     `Ability`) decides everything; `authorization_policy` per resource is ignored.
    #   * **No field-level authorization** — CanCanCan has no per-rule "is it defined?" concept, so
    #     `defines_rule?`/`has_rule?` return false (every field stays visible). Use action_policy or
    #     Pundit if you need field-level rules.
    #   * **`explicit_authorization` has no effect** — CanCanCan denies whatever the Ability doesn't
    #     grant; there's no `manage?`/undefined-rule fallback. Grant access in your Ability.
    #   * `true_user` (impersonation) is not passed to the Ability.
    #   * The index scope follows the Ability's rules for the action (e.g. `can :read, Post, ...`);
    #     with no matching rule it resolves to an empty relation, the CanCanCan way.
    class CanCanCanAdapter < Adapter
      def authorize_action(rule, record: nil, raise_exception: true)
        return true unless RubyUIAdmin.configuration.authorization_enabled?

        target = record.nil? ? @record : record
        action = cancan_action(rule)
        result = ability.can?(action, target)

        if !result && raise_exception
          raise NotAuthorizedError, "Not authorized to #{action} on #{target.inspect}"
        end

        result
      end

      def apply_policy(scope)
        return scope unless RubyUIAdmin.configuration.authorization_enabled?

        scope.accessible_by(ability)
      rescue CanCan::Error
        scope
      end

      # Field-level authorization is not supported by CanCanCan (no per-rule definition concept).
      def has_rule?(_rule, record: nil) = false

      def defines_rule?(_rule) = false

      private

      def ability
        @ability ||= ability_class.new(user)
      end

      def ability_class
        configured = RubyUIAdmin.configuration.cancancan_ability_class || "Ability"
        configured.is_a?(Class) ? configured : Object.const_get(configured.to_s)
      end

      # Admin rule (`show?`, `update?`, …) → CanCanCan action (`:show`, `:update`, …).
      def cancan_action(rule)
        rule.to_s.delete_suffix("?").to_sym
      end
    end
  end
end
