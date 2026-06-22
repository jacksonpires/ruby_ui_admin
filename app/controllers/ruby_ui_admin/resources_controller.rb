# frozen_string_literal: true

module RubyUIAdmin
  class ResourcesController < ApplicationController
    before_action :set_resource
    before_action :set_record, only: %i[show edit update destroy]
    before_action :alias_model_params, only: %i[create update]

    def index
      authorize_action!(:index, on: model_class, policy_class: policy_class)

      query = authorization_for(model_class, policy_class: policy_class).apply_policy(@resource.base_query)
      query = apply_scope(query)
      query = apply_filters(query)
      query = apply_sorting(query)

      limit = RubyUIAdmin.configuration.per_page
      countless = @resource.class.countless || RubyUIAdmin.configuration.countless_pagination?
      @pagy, @records =
        if countless
          pagy_countless(query, limit: limit)
        else
          pagy(query, limit: limit)
        end

      render Views::Index.new(
        resource: @resource,
        records: @records,
        pagy: @pagy,
        filters: @resource.get_filters,
        filter_values: filter_params,
        scopes: @resource.get_scopes,
        current_scope_key: current_scope&.key,
        scope_param: params[:scope],
        remove_scope_all: @resource.remove_scope_all?,
        query_params: request.query_parameters,
        sort_by: params[:sort_by],
        sort_direction: sort_direction
      )
    end

    def show
      authorize_action!(:show, on: @record, policy_class: policy_class)
      @resource.hydrate(record: @record, view: :show)

      # `?tab=N&fragment=1` returns just one tab's content (no page chrome) for lazy tab loading,
      # so that tab's fields/associations are only evaluated when the tab is actually opened.
      if params[:fragment] && params[:tab]
        render Views::ShowTab.new(resource: @resource, record: @record, tab_index: params[:tab].to_i)
      else
        render Views::Show.new(resource: @resource, record: @record)
      end
    end

    def new
      @record = @resource.new_record
      authorize_action!(:create, on: @record, policy_class: policy_class)
      @resource.hydrate(record: @record, view: :new)
      @resource.apply_defaults(@record)

      render Views::Form.new(resource: @resource, record: @record, view: :new)
    end

    def create
      @record = @resource.new_record
      authorize_action!(:create, on: @record, policy_class: policy_class)
      @resource.hydrate(record: @record, view: :new)
      @resource.apply_defaults(@record)
      fill_record(@record, :new)

      if @record.save
        create_success_action
      else
        create_fail_action
      end
    end

    def edit
      authorize_action!(:update, on: @record, policy_class: policy_class)
      @resource.hydrate(record: @record, view: :edit)

      render Views::Form.new(resource: @resource, record: @record, view: :edit)
    end

    def update
      authorize_action!(:update, on: @record, policy_class: policy_class)
      fill_record(@record, :edit)

      if @record.save
        update_success_action
      else
        update_fail_action
      end
    end

    def destroy
      authorize_action!(:destroy, on: @record, policy_class: policy_class)

      if @record.destroy
        destroy_success_action
      else
        destroy_fail_action
      end
    end

    private

    # ---- Lifecycle hooks (override in a per-resource controller) ----

    def create_success_action
      redirect_to after_create_path, notice: create_success_message, status: :see_other
    end

    # Flash messages for the lifecycle hooks. Overridable; also available to host
    # per-resource controllers.
    def create_success_message = "#{resource_label} was successfully created."

    def update_success_message = "#{resource_label} was successfully updated."

    def destroy_success_message = "#{resource_label} was successfully destroyed."

    def create_fail_action
      @resource.hydrate(record: @record, view: :new)
      render Views::Form.new(resource: @resource, record: @record, view: :new), status: :unprocessable_entity
    end

    def update_success_action
      redirect_to after_update_path, notice: update_success_message, status: :see_other
    end

    def update_fail_action
      @resource.hydrate(record: @record, view: :edit)
      render Views::Form.new(resource: @resource, record: @record, view: :edit), status: :unprocessable_entity
    end

    def destroy_success_action
      redirect_to after_destroy_path, notice: destroy_success_message, status: :see_other
    end

    def destroy_fail_action
      redirect_to record_path(@record), alert: "#{resource_label} could not be destroyed.", status: :see_other
    end

    def after_create_path = record_path(@record)

    def after_update_path = record_path(@record)

    def after_destroy_path = resources_index_path

    def set_resource
      resource_class = RubyUIAdmin.resource_manager.find_by_route_key(params[:resource_name])
      raise ActionController::RoutingError, "Unknown resource #{params[:resource_name]}" if resource_class.nil?

      @resource = resource_class.new.hydrate(user: current_user, params: params)
    end

    def set_record
      @record = @resource.find_record(params[:id])
    end

    def model_class
      @resource.model_class
    end

    def policy_class
      @resource.class.authorization_policy
    end

    def resource_label
      @resource.model_class.model_name.human
    end

    # This engine submits form params under `params[:record]`. Mirror them under the model's
    # param key (e.g. `params[:user]`) too, so host controllers that re-read params by the
    # model key keep working.
    def alias_model_params
      return unless params[:record].present?

      key = model_class.model_name.param_key
      params[key] ||= params[:record]
    end

    def fill_record(record, view)
      # Hydrate the resource with the record so field-level authorization is evaluated
      # against it (only authorized fields are permitted/filled).
      @resource.hydrate(record: record, view: view)

      fields = @resource.get_fields(view: view).reject(&:readonly?)
      attributes = params.fetch(:record, ActionController::Parameters.new).permit(*fields.flat_map(&:permit_params))

      fields.each { |field| field.fill(record, attributes) }
    end

    def filter_params
      raw = params[:filters]
      return {} if raw.blank?

      raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
    end

    # The selected scope: explicit `?scope=` wins; `scope=all` clears it; otherwise the
    # resource's default scope (if any) applies.
    def current_scope
      key = params[:scope]
      return nil if key == "all"
      return @resource.find_scope(key) if key.present?

      @resource.default_scope_entry
    end

    def apply_scope(query)
      scope = current_scope
      scope ? scope.apply(query) : query
    end

    def apply_filters(query)
      submitted = filter_params
      @resource.get_filters.each do |filter|
        key = filter.param_key
        # Use the filter's `default` only when its param wasn't submitted at all (so an
        # explicitly-cleared filter stays cleared).
        value = submitted.key?(key) ? submitted[key] : filter.default
        next if value.blank?

        query = filter.apply(request, query, value)
      end
      query
    end

    def apply_sorting(query)
      sort_by = params[:sort_by]
      return query if sort_by.blank?

      field = @resource.find_field(sort_by)
      return query unless field&.sortable?

      if (custom = field.sort_lambda)
        # Custom sort: `sortable: -> { query.reorder(...) }` with `query`, `direction`
        # and `resource` available as readers.
        ExecutionContext.new(target: custom, query: query, direction: sort_direction, resource: @resource).handle
      else
        query.reorder(field.database_id => sort_direction)
      end
    end

    def sort_direction
      params[:sort_direction] == "desc" ? :desc : :asc
    end

    # Path helpers resolving the dynamic per-resource routes.
    def resources_index_path
      helpers.public_send("resources_#{@resource.route_key}_path")
    end

    def record_path(record)
      helpers.public_send("resources_#{@resource.singular_route_key}_path", record)
    end
  end
end
