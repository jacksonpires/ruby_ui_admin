# frozen_string_literal: true

RubyUIAdmin.configure do |config|
  config.app_name = "Dummy Admin"
  config.root_path = "/admin"
  config.per_page = 10

  # Land on the Overview dashboard.
  config.home_path = "/admin/dashboards/overview"

  # Head assets. The dummy acts as the RubyUI host; here it reuses the assets the engine still
  # serves under /ruby-ui-admin-assets (CSS + the importmap + controllers). A real host would
  # point this at its own Tailwind build + bundler/importmap that registers the RubyUI controllers.
  config.head_assets = lambda do
    assets = RubyUIAdmin::ASSETS_MOUNT_PATH
    tags = [tag.link(rel: "stylesheet", href: "#{assets}/application.css")]
    if RubyUIAdmin.configuration.javascript
      imports = %({"imports":{"@hotwired/stimulus":"#{assets}/vendor/stimulus.js","@hotwired/turbo":"#{assets}/vendor/turbo.js"}})
      tags << content_tag(:script, raw(imports), type: "importmap")
      tags << content_tag(:script, raw(%(import "#{assets}/controllers/index.js")), type: "module")
    end
    safe_join(tags)
  end

  # Resolve the current admin user. In the dummy app we just use the first user.
  config.current_user_method { User.first }

  # Sidebar sign-out item (resolved via the host's main_app routes).
  config.sign_out_path_name = :sign_out_path

  # The real (non-impersonated) user — the first admin if there is one (demonstrates
  # the impersonation context that policies can read via `true_user`).
  config.true_user_method { User.where(admin: true).first || User.first }

  # Authentication gate (no-op in the dummy app).
  config.authenticate_with {}

  config.authorization_client = :action_policy
  config.explicit_authorization = false

  # Global, demo-only options. Kept out of the test env so the suite keeps the defaults
  # (auto sidebar nav, non-clickable rows); enabled when running `bin/rails server`.
  if Rails.env.development?
    config.click_row_to_view_record = true

    config.main_menu = lambda do
      section "Content" do
        resource :post
        resource :comment
        resource :tag
      end

      section "People" do
        resource :user, label: "Team"
        resource :profile
      end

      section "Dashboards" do
        all_dashboards
      end

      # The dev-only in-app docs browser (see DocsController).
      link "Docs", "#{config.root_path}/docs"
    end
  end
end
