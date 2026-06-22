# frozen_string_literal: true

require "test_helper"

class ConfigurationIntegrationTest < ActionDispatch::IntegrationTest
  def dated_post
    post = Post.create!(title: "TZ Post")
    post.update_columns(created_at: Time.utc(2026, 3, 1, 0, 0))
    post
  end

  test "renders datetime fields in the configured timezone" do
    acting_admin
    post = dated_post

    with_config(timezone: "Asia/Tokyo") do
      get "/admin/posts/#{post.id}"

      assert_response :success
      assert_includes response.body, "2026-03-01 09:00" # UTC 00:00 -> Tokyo +09:00
    end
  end

  test "datetime fields default to UTC" do
    acting_admin
    post = dated_post

    with_config(timezone: "UTC") do
      get "/admin/posts/#{post.id}"

      assert_includes response.body, "2026-03-01 00:00"
    end
  end

  test "applies a configured locale without breaking the request" do
    acting_admin
    Post.create!(title: "Localized", published: true)

    with_config(locale: :en, timezone: "America/Sao_Paulo") do
      get "/admin/posts"

      assert_response :success
    end
  end
end
