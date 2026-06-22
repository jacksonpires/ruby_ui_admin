# frozen_string_literal: true

require "test_helper"

class I18nTest < ActionDispatch::IntegrationTest
  test "translates framework strings for the configured locale" do
    acting_admin
    Post.create!(title: "Olá", published: true, status: "published")

    with_config(locale: :"pt-BR") do
      get "/admin/posts"

      assert_response :success
      assert_includes response.body, "Ações"  # table header
      assert_includes response.body, "Editar" # row edit action
      assert_includes response.body, "Sim"    # boolean true badge
    end
  end

  test "translates the empty state" do
    acting_admin # no posts

    with_config(locale: :"pt-BR") do
      get "/admin/posts"

      assert_includes response.body, "Nenhum registro encontrado."
    end
  end

  test "field labels use the host's model translations" do
    acting_admin
    post = Post.create!(title: "X", published: true)

    with_config(locale: :"pt-BR") do
      get "/admin/posts/#{post.id}"

      assert_includes response.body, "Título" # activerecord.attributes.post.title
    end
  end

  test "defaults to English" do
    acting_admin
    Post.create!(title: "Y", published: true)

    get "/admin/posts"

    assert_includes response.body, "Actions"
  end
end
