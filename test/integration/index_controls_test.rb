# frozen_string_literal: true

require "test_helper"

# The dummy Post resource defines:
#   self.index_controls = -> { control_link("Invite buyer", "/admin/posts/new") }
class IndexControlsTest < ActionDispatch::IntegrationTest
  test "renders the resource's custom index controls" do
    acting_admin
    Post.create!(title: "Hello", published: true)

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "Invite buyer"
    assert_includes response.body, %(href="/admin/posts/new")
  end

  test "resources without index_controls render none" do
    acting_admin

    get "/admin/users"

    assert_response :success
    refute_includes response.body, "Invite buyer"
  end
end
