# frozen_string_literal: true

require "ruby_ui_admin/version"
require "ruby_ui_admin/configuration"
require "ruby_ui_admin/current"

# Core framework classes (subclassed by host apps). These are framework code, so
# they are required explicitly rather than autoloaded/reloaded.
require "ruby_ui_admin/execution_context"
require "ruby_ui_admin/view"
require "ruby_ui_admin/structure"
require "ruby_ui_admin/fields/field_manager"
require "ruby_ui_admin/fields/base_field"
require "ruby_ui_admin/fields/id_field"
require "ruby_ui_admin/fields/text_field"
require "ruby_ui_admin/fields/textarea_field"
require "ruby_ui_admin/fields/number_field"
require "ruby_ui_admin/fields/boolean_field"
require "ruby_ui_admin/fields/date_field"
require "ruby_ui_admin/fields/date_time_field"
require "ruby_ui_admin/fields/select_field"
require "ruby_ui_admin/fields/url_field"
require "ruby_ui_admin/fields/hidden_field"
require "ruby_ui_admin/fields/password_field"
require "ruby_ui_admin/fields/badge_field"
require "ruby_ui_admin/fields/boolean_group_field"
require "ruby_ui_admin/fields/status_field"
require "ruby_ui_admin/fields/code_field"
require "ruby_ui_admin/fields/key_value_field"
require "ruby_ui_admin/fields/belongs_to_field"
require "ruby_ui_admin/fields/association_field"
require "ruby_ui_admin/fields/has_one_field"
require "ruby_ui_admin/fields/has_many_field"
require "ruby_ui_admin/fields/has_and_belongs_to_many_field"
require "ruby_ui_admin/fields/record_link_field"
require "ruby_ui_admin/fields/file_field"
require "ruby_ui_admin/fields/files_field"
require "ruby_ui_admin/filters/base_filter"
require "ruby_ui_admin/filters/text_filter"
require "ruby_ui_admin/filters/select_filter"
require "ruby_ui_admin/filters/multiple_select_filter"
require "ruby_ui_admin/filters/boolean_filter"
require "ruby_ui_admin/scopes/base_scope"
require "ruby_ui_admin/cards/base_card"
require "ruby_ui_admin/cards/metric_card"
require "ruby_ui_admin/cards/chart_card"
require "ruby_ui_admin/cards/partial_card"
require "ruby_ui_admin/base_resource"
require "ruby_ui_admin/base_action"
require "ruby_ui_admin/base_dashboard"
require "ruby_ui_admin/resource_manager"
require "ruby_ui_admin/dashboard_manager"
require "ruby_ui_admin/menu/builder"
require "ruby_ui_admin/base_policy"
require "ruby_ui_admin/authorization/adapter"
require "ruby_ui_admin/authorization/action_policy_adapter"
require "ruby_ui_admin/authorization"
require "ruby_ui_admin/services/authorization_service"

require "ruby_ui_admin/engine" if defined?(Rails::Engine)

module RubyUIAdmin
  class Error < StandardError; end

  # Raised when authorization fails.
  class NotAuthorizedError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end
    alias_method :config, :configuration

    def configure
      yield configuration if block_given?
      configuration
    end

    # Prepares the resource and dashboard registries. Called on each reload in dev.
    def boot
      resource_manager.boot
      dashboard_manager.boot
    end

    def resource_manager
      @resource_manager ||= ResourceManager.new
    end

    # The controller a resource's routes point to: a per-resource controller when the
    # host defined one (app/controllers/ruby_ui_admin/<route_key>_controller.rb),
    # otherwise the generic "resources" controller.
    def controller_for(resource)
      if defined?(::Rails)
        file = Rails.root.join("app", "controllers", "ruby_ui_admin", "#{resource.route_key}_controller.rb")
        return resource.route_key if File.exist?(file)
      end

      "resources"
    end

    def dashboard_manager
      @dashboard_manager ||= DashboardManager.new
    end

    def reset_resource_manager
      @resource_manager = nil
      @dashboard_manager = nil
    end
  end
end
