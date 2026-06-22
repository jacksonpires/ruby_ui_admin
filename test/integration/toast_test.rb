# frozen_string_literal: true

require "test_helper"

# Flash messages render through RubyUI's Toast component (Stimulus-driven), with a no-JS
# badge fallback. Stimulus + the RubyUI toast controllers are wired via a native importmap.
class ToastTest < ActionDispatch::IntegrationTest
  test "the toaster region and Stimulus wiring ship on every admin page" do
    acting_admin

    get "/admin/posts"

    assert_response :success
    # RubyUI toaster region + controller.
    assert_includes response.body, %(data-controller="ruby-ui--toaster")
    assert_includes response.body, %(id="ruby-ui-toaster-region")
    # Self-hosted Stimulus via importmap (no build step).
    assert_includes response.body, %(type="importmap")
    assert_includes response.body, "/ruby-ui-admin-assets/vendor/stimulus.js"
    assert_includes response.body, "/ruby-ui-admin-assets/controllers/index.js"
  end

  test "a flash message renders as a RubyUI toast item" do
    acting_admin

    # CommentsController#create_success_action sets a custom notice and redirects.
    post "/admin/comments", params: {record: {body: "Hello"}}
    assert_response :redirect
    follow_redirect!

    assert_response :success
    # The flash message is a toast item driven by the per-toast controller (RubyUI Toast).
    assert_includes response.body, %(data-controller="ruby-ui--toast")
    assert_includes response.body, "Custom comment created!"
  end

  test "a no-JS badge fallback is rendered for flash messages" do
    acting_admin

    post "/admin/comments", params: {record: {body: "Hello"}}
    follow_redirect!

    assert_includes response.body, "<noscript>"
  end

  # Turbo is self-hosted (Drive on) for SPA-style navigation; the toaster region is NOT
  # turbo-permanent so each visit re-renders its flash toast.
  test "Turbo is self-hosted and the layout does not opt out of it" do
    acting_admin

    get "/admin/posts"

    assert_includes response.body, %("@hotwired/turbo":"/ruby-ui-admin-assets/vendor/turbo.js")
    refute_includes response.body, %(data-turbo="false")
    refute_includes response.body, "data-turbo-permanent"
  end
end
