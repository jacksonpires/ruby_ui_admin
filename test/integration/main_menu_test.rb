# frozen_string_literal: true

require "test_helper"

# `config.main_menu` renders a curated sidebar instead of the auto-generated resource list.
class MainMenuTest < ActionDispatch::IntegrationTest
  test "renders sections, custom resource labels and arbitrary links" do
    acting_admin

    menu = lambda do
      section "Content", icon: "table" do
        resource :post, label: "Articles"
        link "External docs", "https://example.com/docs"
      end
    end

    with_config(main_menu: menu) do
      get "/admin/posts"
    end

    assert_response :success
    assert_includes response.body, "Content"
    assert_includes response.body, "Articles"
    assert_includes response.body, "https://example.com/docs"
  end

  test "all_resources expands the navigation resources" do
    acting_admin

    menu = -> { section("All") { all_resources(except: [:comments]) } }

    with_config(main_menu: menu) do
      get "/admin/posts"
    end

    assert_response :success
    assert_includes response.body, "/admin/posts"
    assert_includes response.body, "/admin/users"
    refute_includes response.body, ">Comments<"
  end

  test "falls back to auto navigation when no main_menu is configured" do
    acting_admin

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "/admin/posts"
    assert_includes response.body, "/admin/users"
  end
end
