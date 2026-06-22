# frozen_string_literal: true

require "test_helper"

# Post#discussion is a has_many over :comments (for_attribute) scoped to bodies matching
# "keep", linked through the Post resource (use_resource). The plain :comments field links
# via the comments route, so the posts-route hrefs below isolate the `discussion` field.
class AssociationOptionsTest < ActionDispatch::IntegrationTest
  test "for_attribute + scope narrows the association to matching records" do
    admin = acting_admin
    post = Post.create!(title: "P", user: admin)
    keep = post.comments.create!(body: "keep me")
    drop = post.comments.create!(body: "drop me")

    get "/admin/posts/#{post.id}"

    assert_response :success
    # The discussion field (use_resource: Post) links only the scoped-in comment.
    assert_includes response.body, %(href="/admin/posts/#{keep.id}")
    refute_includes response.body, %(href="/admin/posts/#{drop.id}")
  end

  test "use_resource links associated records through the given resource" do
    admin = acting_admin
    post = Post.create!(title: "P", user: admin)
    comment = post.comments.create!(body: "keep this")

    get "/admin/posts/#{post.id}"

    assert_response :success
    # The plain :comments field still links via the comments route...
    assert_includes response.body, %(href="/admin/comments/#{comment.id}")
    # ...while the discussion field routes through Post (use_resource).
    assert_includes response.body, %(href="/admin/posts/#{comment.id}")
  end
end
