# frozen_string_literal: true

require "test_helper"

class JavascriptTest < ActionDispatch::IntegrationTest
  test "serves the Stimulus controller entrypoint" do
    get "/ruby-ui-admin-assets/controllers/index.js"

    assert_response :success
    assert_includes response.body, "rua--tabs"   # registers RubyUI Admin's own controllers
    assert_includes response.body, "ruby-ui--toaster"
  end

  test "loads the Stimulus entrypoint by default" do
    acting_admin
    Post.create!(title: "JS", published: true)

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "/ruby-ui-admin-assets/controllers/index.js"
    assert_includes response.body, %(type="importmap")
  end

  test "does not load javascript when disabled" do
    acting_admin
    Post.create!(title: "JS", published: true)

    with_config(javascript: false) do
      get "/admin/posts"

      assert_response :success
      refute_includes response.body, "/ruby-ui-admin-assets/controllers/index.js"
      refute_includes response.body, %(type="importmap")
    end
  end

  test "renders tab markup driven by the rua--tabs Stimulus controller" do
    acting_admin
    post = Post.create!(title: "Tabbed", published: true, status: "published")

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, %(data-controller="rua--tabs")
    assert_includes response.body, %(data-action="click->rua--tabs#show")
    assert_includes response.body, %(data-rua--tabs-target="nav")
    assert_includes response.body, %(data-rua--tabs-target="panel")
    assert_includes response.body, "data-rua-tab-panel" # key still carries the panel id
  end

  test "renders an action modal driven by rua--dialog with a no-JS fallback link" do
    acting_admin
    post = Post.create!(title: "Acted", published: false, status: "draft")

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, "click->rua--dialog#open"            # trigger opens the modal
    assert_includes response.body, "data-rua--dialog-id-param="         # ...referencing its dialog
    assert_includes response.body, "data-rua-dialog="                   # the dialog itself
    assert_includes response.body, "click->rua--dialog#close"           # backdrop/✕/cancel close it
    assert_includes response.body, %(<turbo-frame id="rua-action-)      # form loads lazily in a frame
    assert_includes response.body, %(loading="lazy")                    # ...on open (non-bulk static src)
    assert_includes response.body, "frame_id=rua-action-"               # src echoes the frame id back
    assert_includes response.body, "/admin/posts/actions/publish_posts" # fallback link to the page
  end

  test "the action form fragment is wrapped in the matching turbo-frame and breaks out on submit" do
    acting_admin
    post = Post.create!(title: "Acted", published: false, status: "draft")

    get "/admin/posts/actions/publish_posts?record_ids[]=#{post.id}&fragment=1&frame_id=rua-action-publish_posts-#{post.id}-frame"

    assert_response :success
    assert_includes response.body, %(<turbo-frame id="rua-action-publish_posts-#{post.id}-frame") # matching wrapper
    assert_includes response.body, %(data-turbo-frame="_top")                                     # submit breaks out
    refute_includes response.body, "<!doctype html"                                               # no page chrome
  end
end
