# frozen_string_literal: true

require "test_helper"

# Post#flags is a `boolean_group` over { "beta" => ..., "pro" => ... } backed by a json column.
class BooleanGroupFieldTest < ActionDispatch::IntegrationTest
  test "renders a checkbox per option on the new form" do
    acting_admin

    get "/admin/posts/new"

    assert_response :success
    assert_includes response.body, %(name="record[flags][beta]")
    assert_includes response.body, %(name="record[flags][pro]")
    assert_includes response.body, "Beta program"
    assert_includes response.body, "Pro features"
  end

  test "persists checked options as true and unchecked as false" do
    acting_admin

    post "/admin/posts", params: {record: {title: "Flagged", flags: {beta: "1", pro: "0"}}}

    assert_response :redirect
    record = Post.find_by(title: "Flagged")
    assert_equal({"beta" => true, "pro" => false}, record.flags)
  end

  test "updates the full hash, clearing previously enabled flags" do
    admin = acting_admin
    record = Post.create!(title: "Existing", user: admin, flags: {"beta" => true, "pro" => true})

    patch "/admin/posts/#{record.id}", params: {record: {title: "Existing", flags: {beta: "1"}}}

    assert_response :redirect
    assert_equal({"beta" => true, "pro" => false}, record.reload.flags)
  end

  test "shows enabled flags on the show page" do
    admin = acting_admin
    record = Post.create!(title: "Shown", user: admin, flags: {"beta" => true, "pro" => false})

    get "/admin/posts/#{record.id}"

    assert_response :success
    assert_includes response.body, "Beta program"
  end
end
