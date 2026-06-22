# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "active_job/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_view/railtie"

require "ruby_ui_admin"

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.2

    config.eager_load = false
    config.consider_all_requests_local = true

    # ActiveStorage: local disk service (for file/files field demos).
    config.active_storage.service = :local

    # Keep logs quiet during tests.
    config.logger = ActiveSupport::Logger.new(File.expand_path("../log/test.log", __dir__))
    config.log_level = :warn
  end
end
