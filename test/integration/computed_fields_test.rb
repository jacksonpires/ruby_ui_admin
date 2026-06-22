# frozen_string_literal: true

require "test_helper"

# Post has computed fields: `quick_link` (block using link_to/current_user/route helper, only_on
# :display) and `status_html` (plain-string block with as_html: true).
class ComputedFieldsTest < ActionDispatch::IntegrationTest
  test "renders a computed block that uses view/url helpers as HTML" do
    admin = acting_admin
    post = Post.create!(title: "Hello World", user: admin)

    get "/admin/posts/#{post.id}"

    assert_response :success
    # link_to output is rendered raw (not escaped) and points at the engine route.
    assert_includes response.body, %(<a href="/admin/posts")
    assert_includes response.body, "Open Hello World"
    refute_includes response.body, "&lt;a href"
  end

  test "as_html renders a plain string block without escaping" do
    admin = acting_admin
    post = Post.create!(title: "Doc", user: admin, status: "published")

    get "/admin/posts/#{post.id}"

    assert_response :success
    assert_includes response.body, %(<em data-test="status-html">published</em>)
  end

  test "only_on :display shows the computed field on index too" do
    admin = acting_admin
    Post.create!(title: "Indexed", user: admin)

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "Open Indexed"
  end
end
