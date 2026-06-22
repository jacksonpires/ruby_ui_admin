# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class ResourceTest < ActiveSupport::TestCase
    test "derives the model class from the resource name" do
      assert_equal Post, Resources::Post.model_class
    end

    test "computes route and singular keys" do
      assert_equal "posts", Resources::Post.route_key
      assert_equal "post", Resources::Post.singular_route_key
    end

    test "collects fields declared in #fields" do
      ids = Resources::Post.new.get_fields.map(&:id)
      assert_includes ids, :title
      assert_includes ids, :user
    end

    test "filters fields by view with only_on" do
      index_ids = Resources::Post.new.get_fields(view: :index).map(&:id)
      assert_includes index_ids, :title
      refute_includes index_ids, :body
    end

    test "reads a field value from a record" do
      field = Resources::Post.new.find_field(:title)
      assert_equal "Hello", field.value(Post.new(title: "Hello"))
    end

    test "belongs_to field maps to the foreign key column" do
      field = Resources::Post.new.find_field(:user)
      assert_equal :user_id, field.database_id
      assert_equal :user_id, field.permitted_param
    end

    test "base_query applies includes" do
      query = Resources::Post.new.base_query
      assert_kind_of ActiveRecord::Relation, query
    end

    test "record_title uses the configured title attribute" do
      resource = Resources::Post.new
      assert_equal "Titled", resource.record_title(Post.new(title: "Titled"))
    end
  end
end
