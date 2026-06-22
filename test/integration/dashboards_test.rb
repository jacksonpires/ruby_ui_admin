# frozen_string_literal: true

require "test_helper"

class DashboardsTest < ActionDispatch::IntegrationTest
  test "renders a dashboard with its cards" do
    acting_admin
    Post.create!(title: "P1", status: "draft", published: false)
    Post.create!(title: "P2", status: "published", published: true)

    get "/admin/dashboards/overview"

    assert_response :success
    assert_includes response.body, "Overview"
    assert_includes response.body, "Total posts"
    assert_includes response.body, "Posts by status"
    assert_includes response.body, ">2<" # the posts count metric
  end

  test "the sidebar links to dashboards" do
    acting_admin

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "/admin/dashboards/overview"
  end

  test "an unknown dashboard raises a routing error" do
    acting_admin

    assert_raises(ActionController::RoutingError) do
      get "/admin/dashboards/does_not_exist"
    end
  end
end
