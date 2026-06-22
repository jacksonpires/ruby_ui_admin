# frozen_string_literal: true

require "test_helper"

# The dummy defines RubyUIAdmin::CommentsController (per-resource) overriding
# create_success_action; Post has no per-resource controller (uses the generic one).
class ResourceControllersTest < ActionDispatch::IntegrationTest
  test "routes a resource to its per-resource controller and runs the overridden hook" do
    acting_admin

    assert_difference -> { Comment.count }, 1 do
      post "/admin/comments", params: {record: {body: "Hello"}}
    end

    assert_response :redirect
    follow_redirect!
    assert_includes response.body, "Custom comment created!"
  end

  test "a resource without a per-resource controller uses the default hooks" do
    acting_admin
    post = Post.create!(title: "P", published: true)

    patch "/admin/posts/#{post.id}", params: {record: {title: "Renamed"}}

    assert_response :redirect
    assert_equal "/admin/posts/#{post.id}", URI(response.location).path # default after_update_path = show
    assert_equal "Renamed", post.reload.title
  end
end
