# frozen_string_literal: true

require "rails/generators/base"

module RubyUIAdmin
  module Generators
    # Wires the admin's Stimulus controllers into the host app, tailored to its JS setup. The gem
    # ships them flat (e.g. `rua--bulk-select_controller.js`) plus an `index.js` that imports and
    # registers every one under the identifier its markup expects (`rua--bulk-select`,
    # `ruby-ui--toaster`, …).
    #
    #   rails g ruby_ui_admin:assets
    #
    # - **Bundler (esbuild/jsbundling/vite):** copies the whole directory verbatim into
    #   `app/javascript/ruby_ui_admin/` (a sibling of `controllers/`, so the host's
    #   `eagerLoadControllersFrom("controllers", …)` doesn't re-register them under bogus names).
    #   The bundler inlines `index.js`'s relative imports, so you just `import "./ruby_ui_admin"`.
    # - **Importmap + Propshaft:** does NOT copy. Copied files get content-digested, and `index.js`'s
    #   relative `./x.js` imports resolve to the *undigested* URLs Propshaft won't serve → 404. Instead
    #   it pins the copy the engine already serves **undigested** via Rack::Static at
    #   `<ASSETS_MOUNT_PATH>/controllers/index.js`, where relative imports work and `@hotwired/stimulus`
    #   / `@hotwired/turbo` resolve through the host's own import map.
    #
    # Either way, no `stimulus:manifest:update` — the shipped `index.js` does the registration.
    class AssetsGenerator < Rails::Generators::Base
      namespace "ruby_ui_admin:assets"
      source_root RubyUIAdmin::Engine.root.to_s

      desc "Sets up the admin's Stimulus controllers (copies for bundlers; pins the served " \
           "entrypoint for importmap)."

      DEST = "app/javascript/ruby_ui_admin"
      # The engine serves its controllers undigested here (see Engine's Rack::Static mount).
      SERVED_INDEX = "#{RubyUIAdmin::ASSETS_MOUNT_PATH}/controllers/index.js"

      def install
        if importmap?
          print_importmap_wiring
        else
          directory "public/ruby-ui-admin-assets/controllers", DEST
          print_bundler_wiring
        end
      end

      private

      def print_importmap_wiring
        say "\nImportmap detected — nothing copied (copied files get digested and index.js's", :green
        say "relative imports would 404 under Propshaft). The engine serves them undigested; pin that:", :green
        say "\n  # config/importmap.rb"
        say %(  pin "ruby_ui_admin", to: "#{SERVED_INDEX}"), :yellow
        say "\n  // app/javascript/application.js"
        say %(  import "ruby_ui_admin"), :yellow
        say "\n(Stimulus + Turbo must be pinned too — stimulus-rails/turbo-rails do that already.)"
      end

      def print_bundler_wiring
        say "\nCopied the admin's Stimulus controllers to #{DEST}/.", :green
        say "Add this import to your JavaScript entrypoint so they're registered:", :yellow
        say "\n  // app/javascript/application.js"
        say %(  import "./ruby_ui_admin"), :yellow
        say "\nThen rebuild your JS bundle. No stimulus:manifest:update needed — the copied"
        say "index.js registers every controller under the right identifier."
      end

      def importmap?
        File.exist?(File.join(destination_root, "config/importmap.rb"))
      end
    end
  end
end
