# frozen_string_literal: true

require "test_helper"

# The delete control opens a confirmation AlertDialog (JS) before submitting; without JS the
# form still submits. The dialog markup ships by default on every admin page.
class DeleteConfirmationTest < ActionDispatch::IntegrationTest
  test "the delete button carries a confirm trigger naming the record" do
    acting_admin
    post = Post.create!(title: "Doomed Post")

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, "click->rua--confirm#request"
    # The message names the record being deleted (carried as a Stimulus action param).
    assert_includes response.body, "data-rua--confirm-message-param"
    assert_includes response.body, "Doomed Post"
  end

  test "the shared confirmation dialog is rendered (hidden) on the layout" do
    acting_admin

    get "/admin/posts"

    assert_response :success
    assert_includes response.body, %(data-controller="rua--confirm")
    assert_includes response.body, %(data-rua--confirm-target="dialog")
    assert_includes response.body, "click->rua--confirm#confirm" # the OK button
  end

  test "the delete form still submits and destroys the record" do
    admin = acting_admin
    post = Post.create!(title: "Doomed Post", user: admin)

    assert_difference -> { Post.count }, -1 do
      delete "/admin/posts/#{post.id}"
    end
    assert_response :redirect
  end
end
