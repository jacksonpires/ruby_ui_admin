# frozen_string_literal: true

module RubyUIAdmin
  module Dashboards
    class Overview < RubyUIAdmin::BaseDashboard
      self.name = "Overview"
      self.description = "Key metrics at a glance."

      def cards
        card RubyUIAdmin::Cards::PostsCount
        card RubyUIAdmin::Cards::AverageViews, suffix: " views"
        card RubyUIAdmin::Cards::PostsByStatus
        card RubyUIAdmin::Cards::WelcomePanel
      end
    end
  end
end
