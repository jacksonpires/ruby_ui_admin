# frozen_string_literal: true

require "test_helper"
require "ruby_ui_admin/authorization/can_can_can_adapter"

# AUTH-3: the CanCanCan adapter maps CRUD rules onto Ability#can? and the index scope onto
# accessible_by. Field-level rules and explicit_authorization are intentionally NOT supported.
class CanCanCanAdapterTest < ActiveSupport::TestCase
  class TestAbility
    include CanCan::Ability

    def initialize(user)
      if user&.admin?
        can :manage, :all
      else
        can :read, Post, published: true
      end
    end
  end

  def build(user, record)
    RubyUIAdmin::Authorization::CanCanCanAdapter.new(user, record)
  end

  def with_ability(&)
    with_config(cancancan_ability_class: "CanCanCanAdapterTest::TestAbility", &)
  end

  test "authorize_action maps CRUD rules to ability actions" do
    admin = User.create!(name: "CA", email: "ccc-admin@example.com", admin: true)
    member = User.create!(name: "CM", email: "ccc-member@example.com", admin: false)
    pub = Post.create!(title: "p", published: true)

    with_ability do
      assert build(admin, Post.new).allowed?(:update) # manage :all
      assert build(member, pub).allowed?(:show)        # read Post (published)
      refute build(member, pub).allowed?(:update)      # not granted
    end
  end

  test "authorize_action raises when denied" do
    member = User.create!(name: "CM2", email: "ccc-m2@example.com", admin: false)
    pub = Post.create!(title: "p2", published: true)

    with_ability do
      assert_raises(RubyUIAdmin::NotAuthorizedError) { build(member, pub).authorize_action(:update) }
    end
  end

  test "apply_policy scopes via accessible_by" do
    admin = User.create!(name: "CA2", email: "ccc-a2@example.com", admin: true)
    member = User.create!(name: "CM3", email: "ccc-m3@example.com", admin: false)
    pub = Post.create!(title: "pub", published: true)
    priv = Post.create!(title: "priv", published: false)

    with_ability do
      member_ids = build(member, Post).apply_policy(Post.all).pluck(:id)
      assert_includes member_ids, pub.id
      refute_includes member_ids, priv.id # member only sees published

      assert_operator build(admin, Post).apply_policy(Post.all).count, :>=, 2 # manage :all
    end
  end

  test "field-level authorization is not supported (defines_rule?/has_rule? false)" do
    with_ability do
      adapter = build(nil, Post.new)
      refute adapter.defines_rule?(:show)
      refute adapter.has_rule?(:view_title)
    end
  end

  test "config.authorization_client = :cancancan resolves to the CanCanCanAdapter" do
    with_config(authorization_client: :cancancan) do
      assert_equal RubyUIAdmin::Authorization::CanCanCanAdapter, RubyUIAdmin::Authorization.adapter_class
    end
  end
end
