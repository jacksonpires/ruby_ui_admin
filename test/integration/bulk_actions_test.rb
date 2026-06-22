# frozen_string_literal: true

require "test_helper"

# Post has a non-standalone action (PublishPosts), so the index gets bulk selection.
class BulkActionsTest < ActionDispatch::IntegrationTest
  test "renders the bulk selection form and a bulk action button" do
    acting_admin
    Post.create!(title: "One", published: true)
    Post.create!(title: "Two", published: true)

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, %(id="rua-bulk-form")
    assert_includes response.body, %(data-controller="rua--bulk-select")
    assert_includes response.body, %(data-rua--bulk-select-target="selectAll")
    assert_includes response.body, "change->rua--bulk-select#toggleAll"
    assert_includes response.body, "data-rua-row-select" # selection hook read by the dialog
    # bulk action button submits the selection to the action page
    assert_includes response.body, %(formaction="/admin/posts/actions/publish_posts")
    assert_includes response.body, %(form="rua-bulk-form")
  end

  test "row checkboxes carry the record id and the bulk form association" do
    acting_admin
    post = Post.create!(title: "One", published: true)

    get "/admin/posts"

    assert_includes response.body, %(name="record_ids[]")
    assert_includes response.body, %(value="#{post.id}")
  end

  test "resources without record actions have no bulk selection" do
    acting_admin
    User.create!(email: "x@example.com")

    get "/admin/users"

    assert_response :success
    refute_includes response.body, "rua-bulk-form"
    refute_includes response.body, "data-rua-row-select"
  end

  test "runs an action against multiple selected records" do
    acting_admin
    a = Post.create!(title: "A", published: false, status: "draft")
    b = Post.create!(title: "B", published: false, status: "draft")

    post "/admin/posts/actions/publish_posts", params: {record_ids: [a.id, b.id]}

    assert_response :redirect
    assert a.reload.published
    assert b.reload.published
  end

  test "the no-JS bulk path renders the action page for the selection" do
    acting_admin
    a = Post.create!(title: "A", published: true)

    get "/admin/posts/actions/publish_posts", params: {record_ids: [a.id]}

    assert_response :success
    assert_includes response.body, "Publish" # the confirmation form
  end
end
