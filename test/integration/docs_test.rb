# frozen_string_literal: true

require "test_helper"

class DocsTest < ActionDispatch::IntegrationTest
  test "the index renders the docs README as HTML" do
    get "/admin/docs"

    assert_response :success
    # README starts with "# RubyUI Admin" -> rendered as an <h1>.
    assert_includes response.body, "<h1"
    assert_includes response.body, "RubyUI Admin"
    # The nav lists other docs.
    assert_includes response.body, "rua-docs-nav"
  end

  test "a nested doc page renders by slug (no .md extension)" do
    get "/admin/docs/getting-started/installation"

    assert_response :success
    assert_includes response.body, "Installation"
  end

  test "a .md extension in the URL also resolves" do
    get "/admin/docs/getting-started/installation.md"

    assert_response :success
    assert_includes response.body, "Installation"
  end

  test "GFM tables and fenced code render" do
    # fields/overview uses GFM tables; ejecting uses tables + code fences.
    get "/admin/docs/customization/ejecting"

    assert_response :success
    assert_includes response.body, "<table"
    assert_includes response.body, "<pre"
  end

  test "relative .md links are rewritten to the docs route" do
    get "/admin/docs"

    assert_response :success
    # README links to docs/README.md (the docs index) and sub-pages; rewritten links point at
    # /admin/docs/... and never carry a raw .md extension.
    assert_includes response.body, "/admin/docs/getting-started/practical-guide"
    refute_includes response.body, 'href="docs/'
    refute_match %r{href="[^"]*\.md"}, response.body
  end

  test "path traversal is blocked" do
    get "/admin/docs/../../../README"
    assert_response :not_found
  rescue ActionController::RoutingError
    # Rack may normalize/reject the traversal before it reaches the engine — also acceptable.
    assert true
  end

  test "an unknown doc returns 404" do
    get "/admin/docs/does/not/exist"
    assert_response :not_found
  end

  test "docs are reachable without authentication in local environments" do
    # No acting user created, and authenticate_with would normally gate admin pages.
    with_config(authenticate_with: -> { redirect_to "/login" }) do
      get "/admin/docs"
      assert_response :success
    end
  end

  test "docs return 404 when disabled (defense in depth, even if the route exists)" do
    with_config(docs_enabled: false) do
      get "/admin/docs"
      assert_response :not_found
    end
  end

  test "in non-local environments docs sit behind the authentication gate" do
    original_env = Rails.env
    Rails.env = "production"

    with_config(docs_enabled: true, authenticate_with: -> { redirect_to "/login" }) do
      get "/admin/docs"
      assert_response :redirect
    end
  ensure
    Rails.env = original_env
  end
end
