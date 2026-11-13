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
    # Never above 7.2 (what the suite was written against), but no higher than the running Rails.
    config.load_defaults [Rails::VERSION::STRING.to_f, 7.2].min

    config.eager_load = false
    config.consider_all_requests_local = true

    # ActiveStorage: local disk service (for file/files field demos).
    config.active_storage.service = :local

    # Keep logs quiet during tests.
    config.logger = ActiveSupport::Logger.new(File.expand_path("../log/test.log", __dir__))
    config.log_level = :warn
  end
end
