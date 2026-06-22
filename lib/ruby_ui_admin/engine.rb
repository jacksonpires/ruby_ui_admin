# frozen_string_literal: true

require "rails/engine"
require "phlex-rails"
require "action_policy"
require "pagy"
# Loaded at engine boot (before host initializers) so hosts that freeze `Pagy::DEFAULT`
# don't hit a FrozenError when this extra is first required.
require "pagy/extras/countless"
require "turbo-rails"
require "tailwind_merge"

module RubyUIAdmin
  # URL prefix where the bundled stylesheet is served (outside the engine mount).
  ASSETS_MOUNT_PATH = "/ruby-ui-admin-assets"

  class Engine < ::Rails::Engine
    isolate_namespace RubyUIAdmin

    # Register inflections as early as possible, before autoload paths are set.
    # The `UI` acronym is needed by BOTH the autoloader (so `ruby_ui_admin/` and
    # `ui/` map to RubyUIAdmin / UI) AND by Rails routing/controller resolution
    # (which camelizes "ruby_ui_admin/resources" via ActiveSupport::Inflector).
    initializer "ruby_ui_admin.inflections", before: :set_autoload_paths do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym "UI"
      end

      Rails.autoloaders.each do |loader|
        loader.inflector.inflect(
          "ruby_ui_admin" => "RubyUIAdmin",
          "ui" => "UI",
          "dsl" => "DSL"
        )
      end
    end

    # Discover host-defined resources/actions/filters/policies in `app/ruby_ui_admin`,
    # namespaced under RubyUIAdmin.
    initializer "ruby_ui_admin.autoload" do |app|
      host_dir = Rails.root.join("app", "ruby_ui_admin").to_s

      ActiveSupport::Dependencies.autoload_paths.delete(host_dir)

      if Dir.exist?(host_dir)
        Rails.autoloaders.main.push_dir(host_dir, namespace: RubyUIAdmin)
        app.config.watchable_dirs[host_dir] = [:rb]
      end
    end

    # Reboot the registry whenever the app reloads in development.
    config.to_prepare do
      RubyUIAdmin.reset_resource_manager
      RubyUIAdmin.boot
    end

    # Provide a `mount_ruby_ui_admin` routing helper.
    initializer "ruby_ui_admin.routing" do
      ActionDispatch::Routing::Mapper.include(Module.new {
        def mount_ruby_ui_admin(at: RubyUIAdmin.configuration.root_path, **options, &block)
          mount RubyUIAdmin::Engine, at:, as: "ruby_ui_admin", **options

          if block
            scope at do
              RubyUIAdmin::Engine.routes.draw(&block)
            end
          end
        end
      })
    end

    # Serve the bundled, precompiled stylesheet at a fixed URL, independent of the
    # host's asset pipeline.
    config.app_middleware.use(
      Rack::Static,
      urls: [RubyUIAdmin::ASSETS_MOUNT_PATH],
      root: RubyUIAdmin::Engine.root.join("public").to_s
    )
  end
end
