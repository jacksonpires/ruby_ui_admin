# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "rails/test_help"
require "action_policy/test_helper"

module ActiveSupport
  class TestCase
    # Tests are self-contained: no `setup`/`teardown`. Each test creates its own data
    # and restores any global state it touches. The helpers below are called
    # explicitly from within a test (never run implicitly).

    # The dummy resolves `current_user` as `User.first`, so the first user created in a
    # test is the acting user.
    def acting_admin(email: "admin@example.com")
      User.create!(email: email, admin: true)
    end

    def acting_member(email: "member@example.com")
      User.create!(email: email, admin: false)
    end

    # Temporarily override RubyUIAdmin configuration for the duration of the block,
    # restoring the previous values afterwards.
    def with_config(**options)
      config = RubyUIAdmin.configuration
      previous = options.keys.to_h { |key| [key, config.public_send(key)] }
      options.each { |key, value| config.public_send("#{key}=", value) }
      yield
    ensure
      previous.each { |key, value| config.public_send("#{key}=", value) }
    end
  end
end
