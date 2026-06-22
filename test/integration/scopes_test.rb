# frozen_string_literal: true

require "test_helper"

# The dummy Post resource declares scopes Published and Drafts (no default).
# Row presence is asserted via the linked title text (">Pub<") to avoid matching the
# "Published" scope-tab label.
class ScopesTest < ActionDispatch::IntegrationTest
  def seed
    acting_admin
    Post.create!(title: "Pub", published: true, status: "published")
    Post.create!(title: "Drft", published: false, status: "draft")
  end

  test "renders a scope tab bar (All + each scope)" do
    seed

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "?scope=all"
    assert_includes response.body, "?scope=published_posts"
    assert_includes response.body, "?scope=draft_posts"
  end

  test "with no scope and no default, shows everything" do
    seed

    get "/admin/posts"

    assert_includes response.body, ">Pub<"
    assert_includes response.body, ">Drft<"
  end

  test "applies the selected scope" do
    seed

    get "/admin/posts", params: {scope: "draft_posts"}
    assert_includes response.body, ">Drft<"
    refute_includes response.body, ">Pub<"

    get "/admin/posts", params: {scope: "published_posts"}
    assert_includes response.body, ">Pub<"
    refute_includes response.body, ">Drft<"
  end

  test "scope=all clears any scope" do
    seed

    get "/admin/posts", params: {scope: "all"}

    assert_includes response.body, ">Pub<"
    assert_includes response.body, ">Drft<"
  end

  test "applies the default scope when no scope param is given" do
    seed
    RubyUIAdmin::Scopes::PublishedPosts.default = true

    get "/admin/posts"

    assert_includes response.body, ">Pub<"
    refute_includes response.body, ">Drft<"
  ensure
    RubyUIAdmin::Scopes::PublishedPosts.default = false
  end

  test "remove_scope_all hides the All tab" do
    seed
    RubyUIAdmin::Resources::Post.remove_scope_all = true

    get "/admin/posts"

    assert_response :success
    refute_includes response.body, "?scope=all"
    assert_includes response.body, "?scope=published_posts"
  ensure
    RubyUIAdmin::Resources::Post.remove_scope_all = false
  end
end
