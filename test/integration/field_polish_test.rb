# frozen_string_literal: true

require "test_helper"

# G14 description (tooltip), G13 visible: lambda, G26a code language.
class FieldPolishTest < ActionDispatch::IntegrationTest
  test "description renders as a label tooltip on the form" do
    acting_admin

    get "/admin/posts/new"

    assert_response :success
    assert_includes response.body, %(title="The post headline")
  end

  test "an admin sees a field gated by a visible: lambda" do
    acting_admin
    Post.create!(title: "Visible Post")

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "admin-only-"
  end

  test "a non-admin does not see a field gated by a visible: lambda" do
    acting_member
    Post.create!(title: "Hidden Post")

    get "/admin/posts"

    assert_response :success
    refute_includes response.body, "admin-only-"
  end

  test "a code field renders its language class for highlighters" do
    admin = acting_admin
    post = Post.create!(title: "Snippet", user: admin)

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, "language-ruby"
  end
end
