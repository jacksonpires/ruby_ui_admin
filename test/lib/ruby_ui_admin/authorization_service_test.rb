# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class AuthorizationServiceTest < ActiveSupport::TestCase
    def service_for(user, record, policy: Policies::PostPolicy)
      Services::AuthorizationService.new(user, record, policy_class: policy)
    end

    test "destroy is allowed for admins and denied for members" do
      admin = acting_admin
      member = acting_member
      post = Post.create!(title: "Published", published: true)

      assert service_for(admin, post).allowed?(:destroy)
      refute service_for(member, post).allowed?(:destroy)
    end

    test "authorize_action raises for a denied rule" do
      member = acting_member
      post = Post.create!(title: "Published", published: true)

      assert_raises(RubyUIAdmin::NotAuthorizedError) do
        service_for(member, post).authorize_action(:destroy, raise_exception: true)
      end
    end

    test "apply_policy scopes members to published records" do
      member = acting_member
      published = Post.create!(title: "Published", published: true)
      Post.create!(title: "Draft", published: false)

      scoped = service_for(member, Post).apply_policy(Post.all)

      assert_equal [published.id], scoped.pluck(:id)
    end

    test "apply_policy returns everything for admins" do
      admin = acting_admin
      Post.create!(title: "Published", published: true)
      Post.create!(title: "Draft", published: false)

      scoped = service_for(admin, Post).apply_policy(Post.all)

      assert_equal 2, scoped.count
    end

    test "missing policy is allowed when explicit_authorization is false" do
      member = acting_member
      service = Services::AuthorizationService.new(member, member, policy_class: nil)

      assert service.allowed?(:index)
    end

    test "missing policy is denied when explicit_authorization is true" do
      member = acting_member

      with_config(explicit_authorization: true) do
        service = Services::AuthorizationService.new(member, member, policy_class: nil)
        refute service.allowed?(:index)
      end
    end
  end
end
