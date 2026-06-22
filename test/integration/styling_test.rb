# frozen_string_literal: true

require "test_helper"

class StylingTest < ActionDispatch::IntegrationTest
  # The layout renders whatever the host supplies via `config.head_assets`. The dummy points it
  # at the stylesheet the engine still serves, so the admin pages link it.
  test "renders the host-provided stylesheet from config.head_assets" do
    acting_admin
    Post.create!(title: "Styled")

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, %(href="/ruby-ui-admin-assets/application.css")
  end

  test "serves the precompiled stylesheet" do
    get "/ruby-ui-admin-assets/application.css"

    assert_response :success
    assert_includes response.body, ".bg-background"
  end

  test "the bundled stylesheet ships with the gem" do
    path = RubyUIAdmin::Engine.root.join("public/ruby-ui-admin-assets/application.css")

    assert path.exist?, "expected compiled stylesheet to be built (rake ruby_ui_admin:build_assets)"
    assert_operator path.size, :>, 1000
  end
end
