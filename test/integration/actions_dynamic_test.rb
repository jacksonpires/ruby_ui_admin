# frozen_string_literal: true

require "test_helper"

# G6 (dynamic message), G7 (route helpers in handle), G8 (file field + indifferent access).
class ActionsDynamicTest < ActionDispatch::IntegrationTest
  CSV_FIXTURE = File.expand_path("../fixtures/files/posts.csv", __dir__)

  test "renders a dynamic message proc using the selected records" do
    acting_admin
    a = Post.create!(title: "A")
    b = Post.create!(title: "B")

    get "/admin/posts/actions/publish_posts", params: {record_ids: [a.id, b.id]}

    assert_response :success
    assert_includes response.body, "Publish 2 selected post(s)?"
  end

  test "a bare route helper in handle resolves the engine path" do
    acting_admin

    post "/admin/posts/actions/import_posts", params: {fields: {count: "1"}}

    assert_response :redirect
    assert_equal "/admin/posts", URI(response.location).path
  end

  test "an action with a file field renders a multipart form with a file input" do
    acting_admin

    get "/admin/posts/actions/import_posts_csv"

    assert_response :success
    assert_includes response.body, %(enctype="multipart/form-data")
    assert_includes response.body, %(type="file")
    assert_includes response.body, "fields[csv_file]"
  end

  test "uploads a file and reads it via indifferent-access field values" do
    acting_admin
    upload = Rack::Test::UploadedFile.new(CSV_FIXTURE, "text/csv")

    assert_difference -> { Post.count }, 2 do
      post "/admin/posts/actions/import_posts_csv", params: {fields: {csv_file: upload}}
    end

    assert_response :redirect
    assert Post.exists?(title: "CSV Post One")
    assert Post.exists?(title: "CSV Post Two")
  end
end
