# frozen_string_literal: true

module RubyUIAdmin
  # Renders an action's form (GET #show) and executes it (POST #run).
  class ActionsController < ApplicationController
    before_action :set_resource
    before_action :set_action_entry
    before_action :set_records

    def show
      action = build_action
      authorize_action!(:act_on, on: authorization_target, policy_class: policy_class)

      # `?fragment=1` returns just the form (no page chrome), wrapped in the modal's matching
      # `<turbo-frame id=frame_id>` so Turbo swaps it in. The action's `fields` are only
      # evaluated when the modal is actually opened (the frame is loaded).
      if params[:fragment]
        render RubyUIAdmin::Views::ActionForm.new(
          resource: @resource,
          action: action,
          action_id: params[:action_id],
          record_ids: @record_ids,
          frame_id: params[:frame_id]
        )
      else
        render Views::Action.new(
          resource: @resource,
          action: action,
          action_id: params[:action_id],
          record_ids: @record_ids
        )
      end
    end

    def run
      action = build_action
      authorize_action!(:act_on, on: authorization_target, policy_class: policy_class)

      action.records = @records
      action.field_values = field_values(action)
      invoke_handle(action)

      process_response(action.response)
    end

    private

    def set_resource
      resource_class = RubyUIAdmin.resource_manager.find_by_route_key(params[:resource_name])
      raise ActionController::RoutingError, "Unknown resource #{params[:resource_name]}" if resource_class.nil?

      @resource = resource_class.new.hydrate(user: current_user, params: params)
    end

    def set_action_entry
      @entry = @resource.find_action_entry(params[:action_id])
      raise ActionController::RoutingError, "Unknown action #{params[:action_id]}" if @entry.nil?
    end

    def set_records
      @record_ids = Array(params[:record_ids]).reject(&:blank?)
      @records = @record_ids.any? ? @resource.base_query.where(id: @record_ids).to_a : []
    end

    def policy_class
      @resource.class.authorization_policy
    end

    def authorization_target
      @records.first || @resource.model_class
    end

    def action_view
      @records.size == 1 ? :show : :index
    end

    def build_action
      action = @resource.instantiate_action(@entry, view: action_view, records: @records)
      action.controller = self
      action
    end

    # Indifferent-access so `handle` can read `fields[:csv_file]` or `fields["csv_file"]`.
    def field_values(action)
      submitted = params[:fields] || {}
      values = action.get_fields.each_with_object({}) do |field, acc|
        acc[field.id.to_s] = submitted[field.id.to_s]
      end
      ActiveSupport::HashWithIndifferentAccess.new(values)
    end

    # Supports both `handle(query:, fields:, current_user:, resource:, **)` and
    # the positional `handle(args)` style (args[:records], args[:fields], ...).
    def invoke_handle(action)
      kwargs = {
        query: @records,
        records: @records,
        fields: action.field_values,
        current_user: current_user,
        resource: @resource
      }

      parameters = action.method(:handle).parameters
      keyword_kinds = parameters.map(&:first)

      if (keyword_kinds & %i[key keyreq keyrest]).any?
        if keyword_kinds.include?(:keyrest)
          action.handle(**kwargs)
        else
          accepted = parameters.select { |(type, _)| %i[key keyreq].include?(type) }.map(&:last)
          action.handle(**kwargs.slice(*accepted))
        end
      else
        action.handle(kwargs)
      end
    end

    def process_response(response)
      case response[:type]
      when :download
        download = response[:download]
        return send_data(download[:content], filename: download[:filename])
      end

      apply_flash(messages_for(response))

      # 303 See Other so Turbo follows the POST→redirect as a GET visit.
      case response[:type]
      when :redirect
        redirect_to resolve_path(response[:path]), status: :see_other
      else # :reload and default
        redirect_back fallback_location: default_back_path, status: :see_other
      end
    end

    # An action that finishes without setting its own message still confirms it ran (Avo
    # parity) — unless it explicitly opted out with `silent`.
    def messages_for(response)
      messages = Array(response[:messages])
      return messages if messages.any? || response[:silent]

      [{type: :success, body: I18n.t("ruby_ui_admin.actions.ran_successfully")}]
    end

    def apply_flash(messages)
      Array(messages).each do |message|
        key = (message[:type] == :error) ? :alert : :notice
        flash[key] = message[:body]
      end
    end

    def resolve_path(path)
      return default_back_path if path.nil?

      path.respond_to?(:call) ? instance_exec(&path) : path
    end

    def default_back_path
      helpers.public_send("resources_#{@resource.route_key}_path")
    end
  end
end
