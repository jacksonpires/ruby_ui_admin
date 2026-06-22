# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class ViewTest < ActiveSupport::TestCase
    test "predicates reflect the underlying view name" do
      assert View.new(:show).show?
      refute View.new(:show).index?
      assert View.new(:index).index?
      assert View.new(:new).form?
      assert View.new(:edit).form?
      assert View.new(:index).display?
      assert View.new(:show).display?
      refute View.new(:new).display?
    end

    test "compares equal to its symbol (view on the left, as in user lambdas)" do
      assert View.new(:show) == :show
      assert View.new(:show) == "show"
      refute View.new(:show) == :index
    end

    test "wrap is idempotent and accepts symbols" do
      wrapped = View.wrap(:edit)
      assert_instance_of View, wrapped
      assert_same wrapped, View.wrap(wrapped)
    end
  end
end
