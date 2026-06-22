# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Resolves the dynamic per-resource engine routes from inside Phlex views.
    # `rc` is a resource class. Engine routes are reached through the mounted
    # `ruby_ui_admin` proxy (provided by RailsHelpers / Routes).
    module PathHelpers
      def resource_index_path(rc)
        ruby_ui_admin.public_send("resources_#{rc.route_key}_path")
      end

      def resource_new_path(rc)
        ruby_ui_admin.public_send("new_resources_#{rc.singular_route_key}_path")
      end

      def resource_show_path(rc, record)
        ruby_ui_admin.public_send("resources_#{rc.singular_route_key}_path", record)
      end

      def resource_edit_path(rc, record)
        ruby_ui_admin.public_send("edit_resources_#{rc.singular_route_key}_path", record)
      end

      # Path to an ActiveStorage blob. Generated via the application's url helpers (NOT the
      # request-bound `main_app` proxy): ActiveStorage's blob route is a `direct` route, and inside
      # a mounted engine the proxy prepends the engine's SCRIPT_NAME (e.g. `/admin/rails/...`),
      # which 404s — AS lives at the host root. `disposition: "attachment"` forces a download.
      def attachment_url(blob, disposition: nil)
        opts = {only_path: true}
        opts[:disposition] = disposition if disposition
        Rails.application.routes.url_helpers.rails_blob_path(blob, **opts)
      end
    end
  end
end
