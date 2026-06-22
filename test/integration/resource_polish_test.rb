# frozen_string_literal: true

require "test_helper"

# G19 tab description, G24 true_user, G23 pagy countless, G26c filter default.
class ResourcePolishTest < ActionDispatch::IntegrationTest
  test "a tab description renders inside the tab panel" do
    admin = acting_admin
    post = Post.create!(title: "P", user: admin)

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, "The main post content"
  end

  test "policies can read true_user (impersonation context)" do
    member = acting_member                                   # current_user (User.first)
    User.create!(email: "boss@example.com", admin: true)     # resolved as true_user
    post = Post.create!(title: "Secret", user: member)
    # show? passes only via the real (admin) user, not the impersonated member.
    RubyUIAdmin::Policies::PostPolicy.define_method(:show?) { true_user&.admin? && !user.admin? }

    get "/admin/posts/#{post.id}"

    assert_response :success
  ensure
    RubyUIAdmin::Policies::PostPolicy.remove_method(:show?)
  end

  test "countless pagination renders prev/next without a total" do
    acting_admin
    12.times { |i| Post.create!(title: "Post #{i}") }
    RubyUIAdmin::Resources::Post.countless = true

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "Next"
    refute_includes response.body, "of 12"
  ensure
    RubyUIAdmin::Resources::Post.countless = false
  end

  test "a filter default is applied when no filter param is submitted" do
    acting_admin
    Comment.create!(body: "keep me")
    Comment.create!(body: "drop me")

    get "/admin/comments"

    assert_response :success
    assert_includes response.body, "keep me"
    refute_includes response.body, "drop me"
  end

  test "an explicitly cleared filter overrides the default" do
    acting_admin
    Comment.create!(body: "keep me")
    Comment.create!(body: "drop me")

    get "/admin/comments", params: {filters: {"comment_body_filter" => ""}}

    assert_response :success
    assert_includes response.body, "keep me"
    assert_includes response.body, "drop me"
  end
end
