# frozen_string_literal: true

require "active_support/current_attributes"

module RubyUIAdmin
  # Thread/request-scoped state, accessible globally as RubyUIAdmin::Current.user etc.
  class Current < ActiveSupport::CurrentAttributes
    attribute :user
    attribute :true_user
    attribute :request
    attribute :view_context
    attribute :resource_manager

    def params
      request.params
    rescue
      {}
    end
  end
end
