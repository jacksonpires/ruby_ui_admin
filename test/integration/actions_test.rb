# frozen_string_literal: true

require "test_helper"

class ActionsTest < ActionDispatch::IntegrationTest
  test "renders a standalone action form" do
    acting_admin

    get "/admin/posts/actions/import_posts"

    assert_response :success
    assert_includes response.body, "Import sample"
    assert_includes response.body, "fields[count]"
  end

  test "runs a standalone action (positional handle signature)" do
    acting_admin

    assert_difference -> { Post.count }, 2 do
      post "/admin/posts/actions/import_posts", params: {fields: {count: "2"}}
    end

    assert_response :redirect
    follow_redirect!
    assert_includes response.body, "Imported 2"
  end

  test "runs a record action (keyword handle signature)" do
    acting_admin
    draft = Post.create!(title: "Draft Post", published: false, status: "draft")

    post "/admin/posts/actions/publish_posts", params: {record_ids: [draft.id]}

    assert_response :redirect
    assert draft.reload.published
    assert_equal "published", draft.status
  end

  test "an action with no explicit message shows a default success toast" do
    acting_admin
    draft = Post.create!(title: "Draft Post", published: true, status: "draft")

    # ArchivePosts#handle sets no message; the controller should still confirm it ran.
    post "/admin/posts/actions/archive_posts", params: {record_ids: [draft.id]}
    assert_response :redirect
    assert_equal "archived", draft.reload.status

    follow_redirect!
    assert_includes response.body, "Action ran successfully."
  end

  test "the show page lists record actions" do
    acting_admin
    draft = Post.create!(title: "Draft Post", published: false, status: "draft")

    get "/admin/posts/#{draft.id}"

    assert_response :success
    assert_includes response.body, "Publish"
  end

  test "the index header lists standalone actions" do
    acting_admin

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "Import sample"
  end

  test "an unknown action raises a routing error" do
    acting_admin

    assert_raises(ActionController::RoutingError) do
      get "/admin/posts/actions/does_not_exist"
    end
  end

  test "act_on? denial forbids running an action" do
    acting_admin
    draft = Post.create!(title: "Draft Post", published: false, status: "draft")

    RubyUIAdmin::Policies::PostPolicy.define_method(:act_on?) { false }

    post "/admin/posts/actions/publish_posts", params: {record_ids: [draft.id]}
    assert_response :forbidden
  ensure
    RubyUIAdmin::Policies::PostPolicy.define_method(:act_on?) { true }
  end
end
