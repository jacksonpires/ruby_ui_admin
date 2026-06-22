# frozen_string_literal: true

require "test_helper"

class FiltersTest < ActionDispatch::IntegrationTest
  def seed_posts
    acting_admin
    Post.create!(title: "Alpha", status: "published", published: true)
    Post.create!(title: "Beta", status: "draft", published: false)
  end

  test "the index renders a filter bar" do
    seed_posts

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "filters[status_filter]"
    assert_includes response.body, "filters[title_filter]"
    assert_includes response.body, "filters[published_filter]"
  end

  test "a select filter narrows results" do
    seed_posts

    get "/admin/posts", params: {filters: {"status_filter" => "draft"}}

    assert_includes response.body, "Beta"
    refute_includes response.body, "Alpha"
  end

  test "a text filter narrows results" do
    seed_posts

    get "/admin/posts", params: {filters: {"title_filter" => "Alph"}}

    assert_includes response.body, "Alpha"
    refute_includes response.body, "Beta"
  end

  test "a boolean filter narrows results" do
    seed_posts

    get "/admin/posts", params: {filters: {"published_filter" => "false"}}

    assert_includes response.body, "Beta"
    refute_includes response.body, "Alpha"
  end

  test "blank filter values are ignored" do
    seed_posts

    get "/admin/posts", params: {filters: {"status_filter" => ""}}

    assert_includes response.body, "Alpha"
    assert_includes response.body, "Beta"
  end

  test "renders multiple-select and hash-based boolean filter controls" do
    seed_posts

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "filters[statuses_filter][]"
    assert_includes response.body, "filters[visibility_filter][published]"
    assert_includes response.body, "filters[visibility_filter][unpublished]"
  end

  test "a multiple-select filter narrows to any of the checked values" do
    seed_posts
    Post.create!(title: "Gamma", status: "archived", published: false)

    get "/admin/posts", params: {filters: {"statuses_filter" => ["draft", "archived"]}}

    assert_includes response.body, ">Beta<"
    assert_includes response.body, ">Gamma<"
    refute_includes response.body, ">Alpha<"
  end

  test "a hash-based boolean filter applies its hash value" do
    seed_posts

    get "/admin/posts", params: {filters: {"visibility_filter" => {"published" => "true", "unpublished" => "false"}}}

    assert_includes response.body, ">Alpha<"
    refute_includes response.body, ">Beta<"
  end
end
