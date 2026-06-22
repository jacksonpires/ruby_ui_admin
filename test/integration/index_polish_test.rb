# frozen_string_literal: true

require "test_helper"

# G21 self.description, G20 record_selector=false, G22 click_row_to_view_record, G25 row_controls.
class IndexPolishTest < ActionDispatch::IntegrationTest
  test "self.description renders as an index subtitle" do
    acting_admin
    RubyUIAdmin::Resources::Post.description = "All blog posts"

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "All blog posts"
  ensure
    RubyUIAdmin::Resources::Post.description = nil
  end

  test "record_selector renders row checkboxes by default" do
    acting_admin
    Post.create!(title: "P")

    get "/admin/posts"

    assert_includes response.body, "data-rua-row-select"
  end

  test "record_selector = false hides the bulk checkbox column" do
    acting_admin
    Post.create!(title: "P")
    RubyUIAdmin::Resources::Post.record_selector = false

    get "/admin/posts"

    assert_response :success
    refute_includes response.body, "data-rua-row-select"
  ensure
    RubyUIAdmin::Resources::Post.record_selector = true
  end

  test "click_row_to_view_record wires the rua--row-link controller on the row" do
    acting_admin
    post = Post.create!(title: "P")

    with_config(click_row_to_view_record: true) do
      get "/admin/posts"
    end

    assert_response :success
    assert_includes response.body, %(data-controller="rua--row-link")
    assert_includes response.body, %(data-rua--row-link-url-value="/admin/posts/#{post.id}")
    assert_includes response.body, "click->rua--row-link#navigate"
  end

  test "row_controls renders custom per-row controls" do
    acting_admin
    post = Post.create!(title: "P")
    RubyUIAdmin::Resources::Post.row_controls = ->(record) { a(href: "/custom/#{record.id}") { "Custom" } }

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, %(href="/custom/#{post.id}")
    assert_includes response.body, "Custom"
  ensure
    RubyUIAdmin::Resources::Post.row_controls = nil
  end
end
