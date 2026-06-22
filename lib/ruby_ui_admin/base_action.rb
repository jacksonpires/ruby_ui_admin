# frozen_string_literal: true

require "active_support/core_ext/class/attribute"

module RubyUIAdmin
  # Base class for custom actions: declarative fields, response helpers and `handle`.
  # Action execution is wired through ActionsController.
  class BaseAction
    class_attribute :message, instance_accessor: false, default: nil
    class_attribute :confirm_button_label, instance_accessor: false, default: "Run"
    class_attribute :cancel_button_label, instance_accessor: false, default: "Cancel"
    class_attribute :standalone, instance_accessor: false, default: false
    class_attribute :no_confirmation, instance_accessor: false, default: false
    class_attribute :visible, instance_accessor: false, default: nil
    class_attribute :authorize, instance_accessor: false, default: true

    class << self
      # Class-level `self.name =` with fallback to the real class name.
      def name=(value)
        @display_name = value
      end

      def name
        @display_name || super
      end

      def action_name
        name
      end

      # URL-safe identifier for this action, stable across namespaces, e.g.
      # RubyUIAdmin::Actions::Users::ResetPassword -> "users_reset_password".
      def action_key
        to_s.sub(/^RubyUIAdmin::Actions::/, "").gsub("::", "_").underscore
      end
    end

    # NOTE: `fields` is the DSL declaration method (below), so submitted values are
    # stored separately as `field_values`.
    attr_accessor :view, :resource, :user, :records, :field_values, :arguments, :current_user
    attr_reader :response
    # The controller running the action, used to expose route helpers inside `handle`.
    attr_writer :controller

    def initialize(view: nil, resource: nil, user: nil, arguments: {})
      @view = view
      @resource = resource
      @user = user
      @current_user = user
      @arguments = arguments || {}
      @records = []
      @response = default_response
    end

    # ---- Action form fields DSL ----

    def field(id, as: :text, **options, &block)
      field_class = Fields.field_class_for(as)
      action_fields << field_class.new(id, **options, &block)
    end

    def action_fields
      @action_fields ||= []
    end

    # Overridden by subclasses to declare action form fields.
    def fields; end

    def get_fields
      @action_fields = []
      fields
      action_fields
    end

    def has_fields?
      get_fields.any?
    end

    # ---- Handler ----

    # Subclasses implement `handle`. Two signatures are supported:
    #   def handle(query:, fields:, current_user:, resource:, **); end
    #   def handle(args); end   # args[:records], args[:fields], args[:current_user]
    def handle(**args); end

    def name
      self.class.name
    end

    # The confirmation message shown in the action modal. Accepts a literal or a proc
    # evaluated with `resource`/`record`/`records` available (dynamic message).
    def message
      msg = self.class.message
      return msg unless msg.respond_to?(:call)

      ExecutionContext.new(
        target: msg,
        view: View.wrap(@view),
        resource: resource,
        record: records&.first,
        records: records,
        current_user: current_user
      ).handle
    end

    # ---- Route helpers (available inside `handle`) ----
    # Expose `main_app.*` (host routes) and the engine route proxy (`ruby_ui_admin.*`),
    # plus bare `*_path`/`*_url` helpers resolved against either.

    def main_app
      @controller&.main_app
    end

    def ruby_ui_admin
      return @controller.ruby_ui_admin if @controller.respond_to?(:ruby_ui_admin)

      RubyUIAdmin::Engine.routes.url_helpers if defined?(RubyUIAdmin::Engine)
    end

    def standalone?
      !!self.class.standalone
    end

    def no_confirmation?
      !!self.class.no_confirmation
    end

    def visible_in_view?(current_view)
      return true if self.class.visible.nil?

      ExecutionContext.new(
        target: self.class.visible,
        view: View.wrap(current_view),
        resource: resource,
        record: (records&.first)
      ).handle
    end

    # ---- Response helpers (mutating @response) ----

    def succeed(text, **opts)
      add_message(:success, text, **opts)
    end

    def error(text, **opts)
      add_message(:error, text, **opts)
    end

    def inform(text, **opts)
      add_message(:info, text, **opts)
    end

    def warn(text, **opts)
      add_message(:warning, text, **opts)
    end

    def redirect_to(path = nil, **opts, &block)
      @response[:type] = :redirect
      @response[:path] = block || path
      @response[:redirect_options] = opts
    end

    def reload
      @response[:type] = :reload
    end

    def keep_modal_open
      @response[:keep_modal_open] = true
    end

    def silent
      @response[:messages] = []
      @response[:silent] = true
    end

    def download(content, filename)
      @response[:type] = :download
      @response[:download] = {content: content, filename: filename}
    end

    # Resolves bare `*_path`/`*_url` calls in `handle` against the engine routes first,
    # then the host app (`main_app`), so e.g. `resources_posts_path` or a host
    # `login_url(...)` work without a prefix.
    def method_missing(name, *args, **kwargs, &block)
      if route_helper?(name)
        [ruby_ui_admin, main_app].compact.each do |helpers|
          return helpers.public_send(name, *args, **kwargs) if helpers.respond_to?(name)
        end
      end
      super
    end

    def respond_to_missing?(name, include_private = false)
      (route_helper?(name) && [ruby_ui_admin, main_app].compact.any? { |h| h.respond_to?(name) }) || super
    end

    private

    def route_helper?(name)
      name.to_s.end_with?("_path", "_url")
    end

    def default_response
      {type: :reload, messages: [], keep_modal_open: false, silent: false}
    end

    def add_message(kind, text, **opts)
      @response[:messages] << {type: kind, body: text, **opts}
    end
  end
end
