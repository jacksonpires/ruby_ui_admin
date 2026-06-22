# frozen_string_literal: true

require "test_helper"

# Covers the second-audit gaps: G27 view predicate, G28 select options params,
# G29 scope description, G30 menu section icon, G31 row_controls_config,
# G32 global countless pagination, G34 row-control button helpers.
class SecondAuditTest < ActionDispatch::IntegrationTest
  # G27 — `visible: -> { view.show? }` shows the field on show, not on index.
  test "view predicate object drives a visible: lambda" do
    admin = acting_admin
    post = Post.create!(title: "P", user: admin)

    get "/admin/posts/#{post.id}"
    assert_response :success
    assert_includes response.body, "note-on-show-#{post.id}"

    get "/admin/posts"
    assert_response :success
    refute_includes response.body, "note-on-show-"
  end

  # G28 — a select `options:` lambda can read request params.
  test "select options lambda reads request params" do
    acting_admin

    get "/admin/posts/new", params: {pick_from: "alpha,beta"}

    assert_response :success
    assert_includes response.body, %(value="alpha")
    assert_includes response.body, "Alpha"
    assert_includes response.body, %(value="beta")
  end

  # G29 — scope description renders as the tab tooltip.
  test "scope description renders as a tooltip on the scope tab" do
    acting_admin
    Post.create!(title: "P")

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, %(title="Only published posts")
  end

  # G30 — a raw SVG section icon renders in the sidebar.
  test "main_menu section icon renders a raw svg" do
    acting_admin
    menu = -> { section("Tables", icon: "<svg data-test=\"sec-icon\"></svg>") { resource :post } }

    with_config(main_menu: menu) do
      get "/admin/posts"
    end

    assert_response :success
    assert_includes response.body, %(data-test="sec-icon")
  end

  # G31 — row_controls_config drives the controls cell layout.
  test "row_controls_config sets placement and mode data attributes" do
    acting_admin
    Post.create!(title: "P")
    RubyUIAdmin::Resources::Post.row_controls_config = {placement: :left, float: true, show_on_hover: true}

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "justify-start"
    assert_includes response.body, "data-rua-row-controls"
  ensure
    RubyUIAdmin::Resources::Post.row_controls_config = {}
  end

  # G32 — global countless pagination via config.pagination.
  test "config.pagination countless paginates without a total" do
    acting_admin
    12.times { |i| Post.create!(title: "Post #{i}") }

    with_config(pagination: {type: :countless}) do
      get "/admin/posts"
    end

    assert_response :success
    assert_includes response.body, "Next"
    refute_includes response.body, "of 12"
  end

  # G34 — show_button helper usable inside row_controls.
  test "show_button helper renders a row control link" do
    admin = acting_admin
    post = Post.create!(title: "P", user: admin)
    RubyUIAdmin::Resources::Post.row_controls = ->(record) { show_button(record, label: "Peek") }

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "Peek"
    assert_includes response.body, %(href="/admin/posts/#{post.id}")
  ensure
    RubyUIAdmin::Resources::Post.row_controls = nil
  end
end
