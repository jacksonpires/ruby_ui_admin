# frozen_string_literal: true

require "test_helper"

# Post#title has `default: "Untitled"`; User#email has `default: -> { current_user&.email }`.
class FieldDefaultsTest < ActionDispatch::IntegrationTest
  test "prefills a literal default on the new form" do
    acting_admin

    get "/admin/posts/new"

    assert_response :success
    assert_includes response.body, %(value="Untitled")
  end

  test "prefills a proc default using current_user" do
    acting_admin(email: "boss@example.com")

    get "/admin/users/new"

    assert_response :success
    assert_includes response.body, %(value="boss@example.com")
  end

  test "submitted values override defaults on create" do
    acting_admin

    post "/admin/posts", params: {record: {title: "Real title", published: "1"}}

    assert_response :redirect
    assert Post.exists?(title: "Real title")
    refute Post.exists?(title: "Untitled")
  end
end
