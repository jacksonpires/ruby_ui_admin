# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class DashboardTest < ActiveSupport::TestCase
    test "dashboard id derives from the class name" do
      assert_equal "overview", Dashboards::Overview.id
    end

    test "title falls back to a humanized name" do
      assert_equal "Overview", Dashboards::Overview.title
    end

    test "get_cards instantiates the declared cards" do
      cards = Dashboards::Overview.new.get_cards
      assert_equal [Cards::PostsCount, Cards::AverageViews, Cards::PostsByStatus, Cards::WelcomePanel], cards.map(&:class)
    end

    test "card type is inherited from the base card" do
      assert_equal :metric, Cards::PostsCount.new.type
      assert_equal :chart, Cards::PostsByStatus.new.type
    end

    test "metric card computes its value via query" do
      Post.create!(title: "x")
      assert_equal Post.count, Cards::PostsCount.new.value
    end

    test "chart card returns a hash of data" do
      Post.create!(title: "x", status: "draft")
      data = Cards::PostsByStatus.new.data
      assert_kind_of Hash, data
      assert_operator data.values.sum, :>=, 1
    end

    test "the manager finds a dashboard by id" do
      assert_equal Dashboards::Overview, RubyUIAdmin.dashboard_manager.find("overview")
    end
  end
end
