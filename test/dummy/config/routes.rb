# frozen_string_literal: true

Rails.application.routes.draw do
  mount_ruby_ui_admin at: "/admin"

  # Demonstrates the sidebar sign-out item (config.sign_out_path_name).
  delete "/sign_out", to: redirect("/admin"), as: :sign_out

  root to: redirect("/admin")
end
