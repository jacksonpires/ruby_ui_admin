# frozen_string_literal: true

require "test_helper"
require "ruby_ui_admin/authorization/pundit_adapter"

# AUTH-2: the Pundit-backed adapter maps the admin's rules onto a Pundit policy + Scope, with the
# same missing-rule/explicit_authorization fallback as action_policy.
class PunditAdapterTest < ActiveSupport::TestCase
  # Minimal Pundit-style policy for Post (defines show?/index? + a Scope; no edit?).
  class PostPunditPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def index? = true

    def show? = !!user&.admin?

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve = @user&.admin? ? @scope.all : @scope.none
    end
  end

  def build(user, record)
    RubyUIAdmin::Authorization::PunditAdapter.new(user, record, policy_class: PostPunditPolicy)
  end

  test "allowed? consults the Pundit policy rule" do
    admin = User.create!(name: "PA", email: "pundit-admin@example.com", admin: true)
    member = User.create!(name: "PM", email: "pundit-member@example.com", admin: false)

    assert build(admin, Post.new).allowed?(:show)
    refute build(member, Post.new).allowed?(:show)
  end

  test "authorize_action raises NotAuthorizedError when denied" do
    member = User.create!(name: "PM2", email: "pundit-m2@example.com", admin: false)

    assert_raises(RubyUIAdmin::NotAuthorizedError) { build(member, Post.new).authorize_action(:show) }
  end

  test "apply_policy resolves through the policy Scope" do
    admin = User.create!(name: "PA2", email: "pundit-a2@example.com", admin: true)
    member = User.create!(name: "PM3", email: "pundit-m3@example.com", admin: false)
    Post.create!(title: "scoped")

    assert_operator build(admin, Post).apply_policy(Post.all).count, :>, 0
    assert_equal 0, build(member, Post).apply_policy(Post.all).count
  end

  test "an undefined rule falls back to explicit_authorization (allowed when false)" do
    admin = User.create!(name: "PA3", email: "pundit-a3@example.com", admin: true)

    assert build(admin, Post.new).allowed?(:edit) # policy has no edit? → fallback, explicit=false
  end

  test "an undefined rule is denied under explicit_authorization" do
    admin = User.create!(name: "PA4", email: "pundit-a4@example.com", admin: true)

    with_config(explicit_authorization: true) do
      refute build(admin, Post.new).allowed?(:edit)
    end
  end

  test "defines_rule? reflects the policy class's public methods" do
    adapter = build(nil, Post.new)

    assert adapter.defines_rule?(:show)
    refute adapter.defines_rule?(:edit)
  end

  test "config.authorization_client = :pundit resolves to the PunditAdapter" do
    with_config(authorization_client: :pundit) do
      assert_equal RubyUIAdmin::Authorization::PunditAdapter, RubyUIAdmin::Authorization.adapter_class
    end
  end
end
