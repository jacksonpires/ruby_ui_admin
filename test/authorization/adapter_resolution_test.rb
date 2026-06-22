# frozen_string_literal: true

require "test_helper"

# AUTH-1: config.authorization_client resolves to an adapter class (symbol via registry, a custom
# class as-is, or the default). The action_policy behaviour itself is covered by the policy/scope/
# field-authorization suites, which all run through the AuthorizationService facade.
class AdapterResolutionTest < ActiveSupport::TestCase
  CustomAdapter = Class.new(RubyUIAdmin::Authorization::Adapter)

  test "the :action_policy symbol resolves to the ActionPolicyAdapter" do
    assert_equal RubyUIAdmin::Authorization::ActionPolicyAdapter,
      RubyUIAdmin::Authorization.adapter_class(:action_policy)
  end

  test "nil (authorization disabled) still resolves to the default adapter" do
    assert_equal RubyUIAdmin::Authorization::ActionPolicyAdapter,
      RubyUIAdmin::Authorization.adapter_class(nil)
  end

  test "a custom adapter class is used as-is" do
    assert_equal CustomAdapter, RubyUIAdmin::Authorization.adapter_class(CustomAdapter)
  end

  test "an unknown client raises with a helpful message" do
    error = assert_raises(ArgumentError) { RubyUIAdmin::Authorization.adapter_class(:nope) }
    assert_includes error.message, "action_policy"
  end

  test "adapter_class reads config.authorization_client by default" do
    with_config(authorization_client: CustomAdapter) do
      assert_equal CustomAdapter, RubyUIAdmin::Authorization.adapter_class
    end
  end

  test "the AuthorizationService facade builds and delegates to the configured adapter" do
    admin = acting_admin
    # Default adapter (action_policy) is built and answers through the facade.
    service = RubyUIAdmin::Services::AuthorizationService.new(admin, Post.new)
    assert_respond_to service, :allowed?
    assert service.allowed?(:index) # no policy → explicit_authorization false → allowed
  end

  # A custom adapter with sentinel return values, to prove the facade actually invokes it.
  class RecordingAdapter < RubyUIAdmin::Authorization::Adapter
    def authorize_action(_rule, record: nil, raise_exception: true) = :authorized
    def apply_policy(_scope) = :scoped
    def has_rule?(_rule, record: nil) = true
    def defines_rule?(_rule) = true
  end

  test "the facade delegates to a custom adapter set via authorization_client" do
    with_config(authorization_client: RecordingAdapter) do
      service = RubyUIAdmin::Services::AuthorizationService.new(nil, nil)

      assert_equal :authorized, service.authorize_action(:show)
      assert_equal :scoped, service.apply_policy(:relation)
      assert service.defines_rule?(:anything)
    end
  end
end
