# frozen_string_literal: true

require "active_support/core_ext/class/subclasses"

module RubyUIAdmin
  # Discovers dashboards defined under RubyUIAdmin::Dashboards in
  # app/ruby_ui_admin/dashboards.
  class DashboardManager
    def boot
      @dashboards = nil
      self
    end

    def dashboards
      @dashboards ||= fetch_dashboards
    end

    def find(id)
      dashboards.find { |dashboard| dashboard.id == id.to_s }
    end

    def any?
      dashboards.any?
    end

    private

    def fetch_dashboards
      eager_load_dashboards

      # Dedupe by name and re-resolve the constant: in development, `descendants` retains
      # stale class versions from previous Zeitwerk reloads (same name), which would show
      # duplicates. Resolving by name keeps only the current class.
      RubyUIAdmin::BaseDashboard.descendants
        .select { |dashboard| !dashboard.abstract? && dashboard.to_s.start_with?("RubyUIAdmin::Dashboards::") }
        .map(&:to_s).uniq
        .filter_map { |name| name.safe_constantize }
    end

    def eager_load_dashboards
      return unless defined?(::Rails)

      dir = Rails.root.join("app", "ruby_ui_admin", "dashboards")
      return unless Dir.exist?(dir)

      loader = Rails.autoloaders.main
      loader.eager_load_dir(dir) if loader.respond_to?(:eager_load_dir)
    rescue NameError
      nil
    end
  end
end
