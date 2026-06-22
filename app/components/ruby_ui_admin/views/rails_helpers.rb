# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Bundles the non-deprecated phlex-rails helper adapters used across views.
    # `Routes` brings the host app url helpers plus mounted-engine proxies, so
    # engine routes are reached via the `ruby_ui_admin` proxy.
    module RailsHelpers
      include Phlex::Rails::Helpers::Routes
      include Phlex::Rails::Helpers::Flash
      include Phlex::Rails::Helpers::FormAuthenticityToken
      include Phlex::Rails::Helpers::Request
    end
  end
end
