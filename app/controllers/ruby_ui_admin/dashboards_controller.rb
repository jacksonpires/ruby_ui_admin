# frozen_string_literal: true

module RubyUIAdmin
  class DashboardsController < ApplicationController
    def show
      dashboard_class = RubyUIAdmin.dashboard_manager.find(params[:dashboard_id])
      raise ActionController::RoutingError, "Unknown dashboard #{params[:dashboard_id]}" if dashboard_class.nil?

      render Views::Dashboard.new(dashboard: dashboard_class.new)
    end
  end
end
