# frozen_string_literal: true

module RubyUIAdmin
  class HomeController < ApplicationController
    def index
      resources = RubyUIAdmin.resource_manager.navigation_resources

      # Redirect to the first resource's index, or the configured home path.
      if (home = RubyUIAdmin.configuration.home_path)
        redirect_to home
      elsif resources.any?
        redirect_to helpers.public_send("resources_#{resources.first.route_key}_path")
      else
        render Views::Home.new(resources: resources)
      end
    end
  end
end
