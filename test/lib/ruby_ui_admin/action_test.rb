# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class ActionTest < ActiveSupport::TestCase
    test "action_key strips the Actions namespace and underscores" do
      assert_equal "publish_posts", Actions::PublishPosts.action_key
      assert_equal "import_posts", Actions::ImportPosts.action_key
    end

    test "succeed accumulates a success message and keeps the default response type" do
      action = Actions::PublishPosts.new
      action.succeed("done")

      assert_equal :reload, action.response[:type]
      assert_equal [{type: :success, body: "done"}], action.response[:messages]
    end

    test "redirect_to sets a redirect response" do
      action = BaseAction.new
      action.redirect_to("/somewhere")

      assert_equal :redirect, action.response[:type]
      assert_equal "/somewhere", action.response[:path]
    end

    test "download sets a download response" do
      action = BaseAction.new
      action.download("data", "file.csv")

      assert_equal :download, action.response[:type]
      assert_equal({content: "data", filename: "file.csv"}, action.response[:download])
    end

    test "standalone and visibility flags" do
      assert Actions::ImportPosts.new.standalone?
      refute Actions::PublishPosts.new.standalone?
    end
  end
end
