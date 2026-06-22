# frozen_string_literal: true

require "pagy"
# `pagy/extras/countless` is required at engine boot (see engine.rb) before host initializers.

module RubyUIAdmin
  class ApplicationController < ActionController::Base
    include Pagy::Backend

    protect_from_forgery with: :exception

    around_action :with_current_context
    before_action :authenticate_admin!

    helper_method :current_user

    rescue_from RubyUIAdmin::NotAuthorizedError do |error|
      render plain: "403 Forbidden — #{error.message}", status: :forbidden
    end

    private

    def with_current_context
      RubyUIAdmin::Current.request = request
      RubyUIAdmin::Current.user = current_user
      RubyUIAdmin::Current.true_user = true_user
      with_admin_locale_and_timezone { yield }
    ensure
      RubyUIAdmin::Current.reset
    end

    # Applies the configured timezone and locale for the duration of the request.
    def with_admin_locale_and_timezone(&block)
      zone = RubyUIAdmin.configuration.timezone
      locale = RubyUIAdmin.configuration.locale

      localized = lambda do
        locale ? I18n.with_locale(locale, &block) : block.call
      end

      zone ? Time.use_zone(zone) { localized.call } : localized.call
    end

    def current_user
      return @current_user if defined?(@current_user)

      method = RubyUIAdmin.configuration.current_user_method
      @current_user =
        if method
          instance_exec(self, &method)
        else
          # Sensible fallback for Warden/Devise hosts when no method is configured.
          request.env["warden"]&.user
        end
    end

    # The real (non-impersonated) user; defaults to `current_user` when no method is set.
    def true_user
      return @true_user if defined?(@true_user)

      method = RubyUIAdmin.configuration.true_user_method
      @true_user = method ? instance_exec(self, &method) : current_user
    end
    helper_method :true_user

    def authenticate_admin!
      block = RubyUIAdmin.configuration.authenticate_with
      instance_exec(&block) if block
    end

    # Builds an authorization service for the current user.
    def authorization_for(record = nil, policy_class: nil)
      Services::AuthorizationService.new(current_user, record, policy_class: policy_class, true_user: true_user)
    end

    # Authorizes a rule or raises NotAuthorizedError.
    def authorize_action!(rule, on:, policy_class: nil)
      authorization_for(on, policy_class: policy_class).authorize_action(rule, raise_exception: true)
    end
  end
end
