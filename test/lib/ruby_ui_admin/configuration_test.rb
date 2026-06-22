# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class ConfigurationTest < ActiveSupport::TestCase
    test "sensible defaults" do
      config = Configuration.new

      assert_equal "RubyUI Admin", config.app_name
      assert_equal "/admin", config.root_path
      assert_nil config.home_path
      assert_equal 24, config.per_page
      assert_equal "UTC", config.timezone
      assert_nil config.locale
      assert_equal :action_policy, config.authorization_client
      refute config.explicit_authorization
      assert config.authorization_enabled?
    end

    test "block options are captured and read back" do
      config = Configuration.new

      config.current_user_method { :a_user }
      config.authenticate_with { :a_gate }

      assert_kind_of Proc, config.current_user_method
      assert_kind_of Proc, config.authenticate_with
    end

    test "authorization is disabled when the client is nil" do
      config = Configuration.new
      config.authorization_client = nil

      refute config.authorization_enabled?
    end

    test "docs_enabled defaults to :local (mounted in dev/test only)" do
      config = Configuration.new

      assert_equal :local, config.docs_enabled
      # The test suite runs in a local environment.
      assert config.docs_enabled?
    end

    test "docs_enabled resolves true/false/proc" do
      config = Configuration.new

      config.docs_enabled = true
      assert config.docs_enabled?

      config.docs_enabled = false
      refute config.docs_enabled?

      config.docs_enabled = -> { false }
      refute config.docs_enabled?

      config.docs_enabled = -> { true }
      assert config.docs_enabled?
    end
  end
end
