# frozen_string_literal: true

require "test_helper"

# Post#views_count uses `sortable: -> { query.reorder(title: direction) }`, so sorting "by
# views_count" actually orders by title — proving the lambda runs instead of the column sort.
class CustomSortingTest < ActionDispatch::IntegrationTest
  test "applies the field's custom sort lambda instead of the column" do
    admin = acting_admin
    # views_count order (Zebra=1, Apple=2) is the inverse of title order.
    Post.create!(title: "Zebra", user: admin, views_count: 1)
    Post.create!(title: "Apple", user: admin, views_count: 2)

    get "/admin/posts?sort_by=views_count&sort_direction=asc"

    assert_response :success
    # Lambda sorts by title asc → Apple before Zebra (column sort would give Zebra first).
    assert_operator response.body.index("Apple"), :<, response.body.index("Zebra")
  end

  test "honors the requested direction in the lambda" do
    admin = acting_admin
    Post.create!(title: "Zebra", user: admin, views_count: 1)
    Post.create!(title: "Apple", user: admin, views_count: 2)

    get "/admin/posts?sort_by=views_count&sort_direction=desc"

    assert_response :success
    # title desc → Zebra before Apple.
    assert_operator response.body.index("Zebra"), :<, response.body.index("Apple")
  end
end
