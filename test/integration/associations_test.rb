# frozen_string_literal: true

require "test_helper"

# The dummy Post resource shows `belongs_to :user` and `has_many :comments`.
# PostPolicy gates the comments association with `view_comments? = !!user&.admin?`.
class AssociationsTest < ActionDispatch::IntegrationTest
  test "renders a has_many association as linked records on show" do
    acting_admin
    post = Post.create!(title: "Parent", published: true)
    comment = Comment.create!(post: post, body: "First comment")

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, "First comment"                       # comment label
    assert_includes response.body, %(href="/admin/comments/#{comment.id}") # links to its show
    assert_includes response.body, "1 item"                              # count
  end

  test "limits has_many association table columns with the fields: option" do
    acting_admin
    post = Post.create!(title: "Parent", published: true)
    comment = Comment.create!(post: post, body: "First comment")

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, "First comment"                        # body column shown
    assert_includes response.body, %(href="/admin/comments/#{comment.id}") # body links to its show
    # `:comments` uses `fields: %i[body created_at]`, so the Comment's `post` belongs_to
    # column is excluded — there's no link back to the parent post from the comments table.
    refute_includes response.body, %(href="/admin/posts/#{post.id}")
  end

  test "renders a belongs_to association as a link on show" do
    user = acting_admin
    post = Post.create!(title: "Owned", published: true, user: user)

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, %(href="/admin/users/#{user.id}")
  end

  test "hides an association the user is not authorized to view" do
    acting_member
    post = Post.create!(title: "Parent", published: true)
    Comment.create!(post: post, body: "Secret comment")

    get "/admin/posts/#{post.id}"

    assert_response :success
    refute_includes response.body, "Secret comment" # view_comments? is admin-only
  end

  test "shows the association for an admin" do
    acting_admin
    post = Post.create!(title: "Parent", published: true)
    Comment.create!(post: post, body: "Visible comment")

    get "/admin/posts/#{post.id}"

    assert_includes response.body, "Visible comment"
  end
end
