# frozen_string_literal: true

module RubyUIAdmin
  # Central configuration object, configured through `RubyUIAdmin.configure`.
  class Configuration
    # Branding / app
    attr_accessor :app_name
    attr_accessor :root_path
    attr_accessor :home_path
    attr_accessor :timezone
    attr_accessor :locale

    # Pagination
    attr_accessor :per_page
    attr_accessor :per_page_steps

    # Authentication
    attr_writer :current_user_method
    attr_writer :authenticate_with
    # Name of a host route helper (resolved via `main_app`) for signing out. When set, a
    # sign-out item renders at the bottom of the sidebar. e.g. :destroy_user_session_path
    attr_accessor :sign_out_path_name
    # HTTP method used by the sign-out item (Devise uses :delete).
    attr_accessor :sign_out_method

    # Authorization
    attr_accessor :authorization_client
    attr_accessor :explicit_authorization
    attr_accessor :raise_error_on_missing_policy

    # Ability class for the CanCanCan adapter (`authorization_client = :cancancan`). A class or its
    # name; defaults to the conventional `Ability`. Ignored by other adapters.
    attr_accessor :cancancan_ability_class

    # Resource discovery
    attr_accessor :resources
    attr_accessor :model_resource_mapping

    # Menus
    attr_writer :main_menu
    attr_writer :profile_menu

    # When true (default), the layout loads the bundled JS (tabs, dialogs). The admin
    # works without it (progressive enhancement); set to false to opt out.
    attr_accessor :javascript

    # Head assets (stylesheet + JS tags) for the admin layout. The admin renders the host's
    # RubyUI components, so the host owns the CSS (Tailwind build) and JS (bundler/importmap that
    # registers the RubyUI Stimulus controllers + ours). Set this to a proc that returns the
    # `<head>` asset markup; it's evaluated in the Rails view context, so it can call helpers like
    # `stylesheet_link_tag` / `javascript_importmap_tags`. When nil, the layout renders no assets.
    attr_accessor :head_assets

    # When true, clicking an index row navigates to the record's show page (needs JS).
    attr_accessor :click_row_to_view_record

    # When true, non-active tabs on the show view load their content lazily (fetched via JS
    # when the tab is first opened, with a spinner) instead of all rendering up front. Needs JS;
    # without JS the active tab still renders and the others show a "requires JavaScript" notice.
    attr_accessor :lazy_tabs

    # Controls the in-app docs browser mounted at `<mount>/docs` (renders the gem's `docs/*.md`).
    # Accepts:
    #   :local (default) — mounted in development/test only
    #   true             — mounted in all environments, including production (where it sits behind
    #                       the admin authentication gate; locally it stays open)
    #   false            — never mounted
    #   a callable        — evaluated at boot/route-draw time; truthy enables it
    # Needs `kramdown` + `kramdown-parser-gfm` available in the running environment's bundle.
    attr_accessor :docs_enabled

    # Global pagination options, e.g. `{ type: :countless }` (or a proc returning it) to
    # paginate without a COUNT query across all resources. Per-resource `self.countless`
    # can still opt in individually.
    attr_writer :pagination

    def initialize
      @app_name = "RubyUI Admin"
      @root_path = "/admin"
      @home_path = nil
      @timezone = "UTC"
      @locale = nil

      @per_page = 24
      @per_page_steps = [12, 24, 48, 72]

      @current_user_method = nil
      @true_user_method = nil
      @authenticate_with = nil
      @sign_out_path_name = nil
      @sign_out_method = :delete

      @authorization_client = :action_policy
      @explicit_authorization = false
      @raise_error_on_missing_policy = false
      @cancancan_ability_class = nil

      @resources = nil
      @model_resource_mapping = {}

      @main_menu = nil
      @profile_menu = nil

      @javascript = true
      @head_assets = nil
      @click_row_to_view_record = false
      @lazy_tabs = false
      @docs_enabled = :local
      @pagination = {}
    end

    # Resolved pagination options (calls the proc form if given).
    def pagination
      @pagination.respond_to?(:call) ? @pagination.call : (@pagination || {})
    end

    # Whether pagination should run without a COUNT query globally.
    def countless_pagination?
      pagination[:type].to_s == "countless"
    end

    # Resolve the current user from the host app context (usually a controller).
    def current_user_method(&block)
      if block_given?
        @current_user_method = block
      else
        @current_user_method
      end
    end

    # Resolve the real (non-impersonated) user. Defaults to `current_user` when unset.
    def true_user_method(&block)
      if block_given?
        @true_user_method = block
      else
        @true_user_method
      end
    end

    def authenticate_with(&block)
      if block_given?
        @authenticate_with = block
      else
        @authenticate_with
      end
    end

    def main_menu(&block)
      if block_given?
        @main_menu = block
      else
        @main_menu
      end
    end

    def profile_menu(&block)
      if block_given?
        @profile_menu = block
      else
        @profile_menu
      end
    end

    def authorization_enabled?
      !authorization_client.nil?
    end

    # Whether the in-app docs browser is available in the current environment.
    def docs_enabled?
      case docs_enabled
      when nil, :local then Rails.env.local?
      when Proc then !!docs_enabled.call
      else !!docs_enabled
      end
    end
  end
end
