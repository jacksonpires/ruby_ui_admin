# frozen_string_literal: true

require "test_helper"

# The dummy Post show has two tabs: "Content" (eager, first) and "Details" (which holds the
# comments association). With config.lazy_tabs the Details tab loads its content on demand.
class LazyTabsTest < ActionDispatch::IntegrationTest
  test "non-active tabs defer their content when config.lazy_tabs is on" do
    acting_admin
    post = Post.create!(title: "Parent", published: true)
    Comment.create!(post: post, body: "First comment")

    with_config(lazy_tabs: true) do
      get "/admin/posts/#{post.id}"
    end

    assert_response :success
    assert_includes response.body, "Parent"                     # first tab renders eagerly
    assert_includes response.body, %(<turbo-frame id="rua-tab-frame-1") # Details deferred in a frame
    assert_includes response.body, %(loading="lazy")
    assert_includes response.body, "fragment=1"                 # ...via the frame src
    assert_includes response.body, "data-rua-tab-spinner"
    refute_includes response.body, "First comment"              # Details content is not rendered yet
  end

  test "the tab fragment renders only that tab's content without page chrome" do
    acting_admin
    post = Post.create!(title: "Parent", published: true)
    Comment.create!(post: post, body: "First comment")

    get "/admin/posts/#{post.id}?tab=1&fragment=1"

    assert_response :success
    assert_includes response.body, %(<turbo-frame id="rua-tab-frame-1") # matching frame wrapper
    assert_includes response.body, "First comment"                   # the Details tab content
    refute_includes response.body, "<!doctype html"                  # no page chrome/layout
    refute_includes response.body, %(data-controller="ruby-ui--sidebar")
  end

  test "tabs render eagerly by default" do
    acting_admin
    post = Post.create!(title: "Parent", published: true)
    Comment.create!(post: post, body: "First comment")

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, "First comment"   # Details content rendered inline
    refute_includes response.body, "rua-tab-frame"     # no deferred tab frames (action-modal frames are unrelated)
  end
end
