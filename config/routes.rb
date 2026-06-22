# frozen_string_literal: true

RubyUIAdmin::Engine.routes.draw do
  root to: "home#index"

  # In-app docs browser: renders the gem's `docs/*.md` as HTML at `<mount>/docs`.
  # Gated by `config.docs_enabled` (default `:local` — development/test only). When enabled in
  # production it sits behind the admin authentication gate (see DocsController).
  if RubyUIAdmin.configuration.docs_enabled?
    get "/docs", to: "docs#show", as: :docs
    get "/docs/*path", to: "docs#show", as: :doc, format: false
  end

  get "/dashboards/:dashboard_id", to: "dashboards#show", as: :dashboard

  # Custom actions (declared before the dynamic resource routes so the 3-segment
  # action path takes precedence). GET renders the action form, POST runs it.
  get "/:resource_name/actions/:action_id", to: "actions#show", as: :resource_action
  post "/:resource_name/actions/:action_id", to: "actions#run"

  # Per-resource RESTful routes, generated from the resource registry.
  draw(:dynamic_routes)
end
