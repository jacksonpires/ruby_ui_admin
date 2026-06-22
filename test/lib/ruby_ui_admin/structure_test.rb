# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class StructureTest < ActiveSupport::TestCase
    test "field_structure exposes tabs and panels" do
      structure = Resources::Post.new.field_structure(view: :show)

      group = structure.find { |item| item.is_a?(Structure::TabGroup) }
      assert group, "expected a TabGroup in the structure"
      assert_equal ["Content", "Details"], group.tabs.map(&:name)

      content_tab = group.tabs.first
      assert(content_tab.items.any? { |item| item.is_a?(Structure::Panel) })
    end

    test "get_fields flattens tabs/panels into field leaves" do
      ids = Resources::Post.new.get_fields.map(&:id)
      assert_includes ids, :title
      assert_includes ids, :views_count
      assert_includes ids, :user
    end

    test "view filtering prunes fields and empty containers" do
      index_ids = Resources::Post.new.get_fields(view: :index).map(&:id)
      assert_includes index_ids, :title
      refute_includes index_ids, :body      # only_on show/new/edit
      refute_includes index_ids, :metadata  # only_on show/new/edit
    end

    test "discover_columns builds fields from the schema" do
      klass = Class.new(RubyUIAdmin::BaseResource) do
        self.model_class = Post
        def fields = discover_columns(only: %i[id title published])
      end

      types = klass.new.get_fields.to_h { |f| [f.id, f.type] }
      assert_equal({id: :id, title: :text, published: :boolean}, types)
    end

    test "discover_associations builds association fields" do
      klass = Class.new(RubyUIAdmin::BaseResource) do
        self.model_class = Post
        def fields = discover_associations(only: %i[user comments])
      end

      fields = klass.new.get_fields(view: :show)
      assert_equal({user: :belongs_to, comments: :has_many}, fields.to_h { |f| [f.id, f.type] })
    end
  end
end
