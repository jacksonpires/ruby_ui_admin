# frozen_string_literal: true

require "test_helper"

# PostPolicy defines `view_views_count? = !!user&.admin?`, so the views_count field
# is only visible/editable for admins.
class FieldAuthorizationTest < ActionDispatch::IntegrationTest
  def published_post
    Post.create!(title: "Pub", published: true, status: "published", views_count: 123)
  end

  test "hides an unauthorized field column on the index for a non-admin" do
    acting_member
    published_post

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "Title"        # sanity: other columns still show
    refute_includes response.body, "Views count"  # authorized-only field hidden
  end

  test "shows the field column for an admin" do
    acting_admin
    published_post

    get "/admin/posts"

    assert_includes response.body, "Views count"
  end

  test "hides the field on the show view for a non-admin" do
    acting_member
    post = published_post

    get "/admin/posts/#{post.id}"

    assert_response :success
    refute_includes response.body, "Views count"
  end

  test "shows the field with its value for an admin" do
    acting_admin
    post = published_post

    get "/admin/posts/#{post.id}"

    assert_includes response.body, "Views count"
    assert_includes response.body, "123"
  end

  test "does not permit filling an unauthorized field" do
    acting_member
    post = published_post

    patch "/admin/posts/#{post.id}", params: {record: {title: "Renamed", views_count: "999"}}

    assert_response :redirect
    post.reload
    assert_equal "Renamed", post.title # authorized field updated
    assert_equal 123, post.views_count # unauthorized field left untouched
  end

  test "permits filling the field for an admin" do
    acting_admin
    post = published_post

    patch "/admin/posts/#{post.id}", params: {record: {views_count: "999"}}

    assert_response :redirect
    assert_equal 999, post.reload.views_count
  end
end
