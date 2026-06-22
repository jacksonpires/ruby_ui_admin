# frozen_string_literal: true

require "test_helper"

class ResourcesCrudTest < ActionDispatch::IntegrationTest
  test "index renders and scopes records via the policy" do
    acting_member
    Post.create!(title: "Published Post", published: true)
    Post.create!(title: "Draft Post", published: false)

    get "/admin/posts"

    assert_response :success
    assert_includes @response.body, "Published Post"
    refute_includes @response.body, "Draft Post"
  end

  test "show renders a record" do
    acting_member
    published = Post.create!(title: "Published Post", published: true)

    get "/admin/posts/#{published.id}"

    assert_response :success
    assert_includes @response.body, "Published Post"
  end

  test "show renders tabs and a status badge" do
    acting_member
    published = Post.create!(title: "Published Post", published: true, status: "published")

    get "/admin/posts/#{published.id}"

    assert_response :success
    assert_includes @response.body, "Content"           # tab name
    assert_includes @response.body, "Details"           # tab name
    assert_includes @response.body, "ring-1 ring-inset" # badge styling
  end

  test "new form renders inputs for editable fields only" do
    acting_member

    get "/admin/posts/new"

    assert_response :success
    assert_includes @response.body, "record[title]"
    assert_includes @response.body, "record[metadata]"
    refute_includes @response.body, "record[id]" # id is not editable
  end

  test "new renders the form" do
    acting_member

    get "/admin/posts/new"

    assert_response :success
    assert_includes @response.body, "Create"
  end

  test "create persists a record and redirects" do
    acting_member

    assert_difference -> { Post.count }, 1 do
      post "/admin/posts", params: {record: {title: "Brand New", published: "1"}}
    end

    assert_response :redirect
    assert Post.exists?(title: "Brand New")
  end

  test "create re-renders the form on validation errors" do
    acting_member

    assert_no_difference -> { Post.count } do
      post "/admin/posts", params: {record: {title: ""}}
    end

    assert_response :unprocessable_entity
  end

  test "update persists changes" do
    acting_member
    published = Post.create!(title: "Published Post", published: true)

    patch "/admin/posts/#{published.id}", params: {record: {title: "Renamed"}}

    assert_response :redirect
    assert_equal "Renamed", published.reload.title
  end

  test "destroy is forbidden for a non-admin" do
    acting_member
    published = Post.create!(title: "Published Post", published: true)

    assert_no_difference -> { Post.count } do
      delete "/admin/posts/#{published.id}"
    end

    assert_response :forbidden
  end

  test "destroy is allowed for an admin" do
    acting_admin
    published = Post.create!(title: "Published Post", published: true)

    assert_difference -> { Post.count }, -1 do
      delete "/admin/posts/#{published.id}"
    end

    assert_response :redirect
  end

  test "the home page redirects to the first resource" do
    acting_member

    get "/admin"

    assert_response :redirect
  end
end
