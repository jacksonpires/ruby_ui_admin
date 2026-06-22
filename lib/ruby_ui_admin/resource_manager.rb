# frozen_string_literal: true

require "active_support/core_ext/class/subclasses"

module RubyUIAdmin
  # Discovers and indexes the host app's resources (defined under
  # `RubyUIAdmin::Resources` in `app/ruby_ui_admin/resources`).
  class ResourceManager
    def boot
      @resources = nil
      self
    end

    def resources
      @resources ||= fetch_resources
    end

    # All resources visible in the sidebar navigation.
    def navigation_resources
      resources.select { |resource| resource.visible_on_sidebar }
    end

    # Find a resource class by its route key, e.g. "buyers".
    def find_by_route_key(key)
      key = key.to_s
      resources.find { |resource| resource.route_key == key } ||
        resources.find { |resource| resource.resource_name == key.singularize }
    end

    # Find the resource class for a given model class.
    def find_for_model(model_class)
      mapped = RubyUIAdmin.configuration.model_resource_mapping[model_class.to_s]
      return mapped.to_s.constantize if mapped

      resources.find { |resource| resource.model_class == model_class }
    end

    private

    def fetch_resources
      eager_load_resources!

      selected = RubyUIAdmin::BaseResource.descendants.select do |resource|
        next false if resource.abstract?

        # Only real, named resources count — excludes anonymous subclasses (e.g.
        # those built in tests) that would otherwise pollute the registry.
        name = resource.name
        name && (RubyUIAdmin.configuration.resources.present? || name.start_with?("RubyUIAdmin::Resources::"))
      end

      # Dedupe by name and re-resolve the constant: in development, `descendants` retains
      # stale class versions from previous Zeitwerk reloads (same name) — keep the current one.
      selected.map(&:name).uniq.filter_map { |name| name.safe_constantize }
    end

    def eager_load_resources!
      configured = RubyUIAdmin.configuration.resources

      if configured.present?
        Array(configured).each { |name| name.to_s.constantize }
      elsif defined?(::Rails)
        eager_load_resources_dir
      end
    rescue NameError
      nil
    end

    def eager_load_resources_dir
      dir = Rails.root.join("app", "ruby_ui_admin", "resources")
      return unless Dir.exist?(dir)

      loader = Rails.autoloaders.main
      if loader.respond_to?(:eager_load_dir)
        loader.eager_load_dir(dir)
      else
        # Fallback for older Zeitwerk: reference the namespace to trigger loading.
        loader.eager_load_namespace(RubyUIAdmin::Resources) if defined?(RubyUIAdmin::Resources)
      end
    end
  end
end
