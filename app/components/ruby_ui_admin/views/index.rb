# frozen_string_literal: true

module RubyUIAdmin
  module Views
    class Index < Base
      include ActionsMenu

      def initialize(resource:, records:, pagy:, filters: [], filter_values: {}, scopes: [], current_scope_key: nil, scope_param: nil, remove_scope_all: false, query_params: {}, sort_by: nil, sort_direction: nil)
        @resource = resource
        @records = records
        @pagy = pagy
        @filters = filters
        @filter_values = filter_values
        @scopes = scopes
        @current_scope_key = current_scope_key
        @scope_param = scope_param
        @remove_scope_all = remove_scope_all
        @query_params = query_params
        @sort_by = sort_by
        @sort_direction = sort_direction
      end

      def page_title
        "#{@resource.navigation_label} · #{RubyUIAdmin.configuration.app_name}"
      end

      BULK_FORM_ID = "rua-bulk-form"

      def content
        render_header
        render_scope_tabs
        render_filter_bar
        render_bulk_toolbar
        # The `rua--bulk-select` controller (select-all + checked-ids) scopes to this table card.
        card_attrs = {class: "p-4"}
        card_attrs[:data] = {controller: "rua--bulk-select"} if bulk?
        render RubyUI::Card.new(**card_attrs) do
          render_table
        end
        render_pagination
      end

      private

      def policy_class
        @resource.class.authorization_policy
      end

      def fields
        @fields ||= @resource.get_fields(view: :index)
      end

      # Non-standalone actions become bulk actions (run against selected rows).
      def bulk_actions
        return [] unless authorized_to?(:act_on, @resource.model_class, policy_class: policy_class)

        @bulk_actions ||= @resource.actions_for(view: :index).reject(&:standalone?)
      end

      def bulk?
        @resource.class.record_selector && bulk_actions.any?
      end

      def render_header
        div(class: "flex items-center justify-between mb-6") do
          div do
            h1(class: "text-2xl font-semibold tracking-tight") { @resource.navigation_label }
            if (description = @resource.class.description)
              p(class: "text-sm text-muted-foreground mt-1") { description }
            end
          end

          div(class: "flex items-center gap-2") do
            render_index_controls
            render_standalone_actions

            if authorized_to?(:create, @resource.model_class, policy_class: policy_class)
              render(RubyUI::Link.new(href: resource_new_path(@resource.class), variant: :primary)) do
                rua_t("actions.new", model: @resource.model_class.model_name.human)
              end
            end
          end
        end
      end

      # Renders the resource's `self.index_controls` block (custom header buttons/links).
      # The block is evaluated in this component, so it can use Phlex (`a`, `button`, …),
      # the `control_link` helper, route helpers (`ruby_ui_admin.*`) and `@resource`.
      def render_index_controls
        controls = @resource.class.index_controls
        return if controls.nil?

        instance_exec(&controls)
      end

      # `actions_list` is accepted inside `index_controls` for compatibility, but standalone
      # actions are already rendered in the header (`render_standalone_actions`), so it is a
      # no-op here.
      def actions_list = nil

      # Convenience helper for `index_controls`: a button-styled link (RubyUI Button as `<a>`).
      def control_link(label, href, variant: :outline)
        render(RubyUI::Link.new(href: href, variant: (variant == :primary) ? :primary : :outline)) { label }
      end

      # Link helpers for use inside `index_controls`/`row_controls` blocks.
      def show_button(record, label: nil)
        a(href: resource_show_path(@resource.class, record), class: "text-sm text-primary hover:underline") { label || rua_t("actions.show") }
      end

      def edit_button(record, label: nil)
        a(href: resource_edit_path(@resource.class, record), class: "text-sm text-primary hover:underline") { label || rua_t("actions.edit") }
      end

      def create_button(label: nil)
        control_link(label || rua_t("actions.new", model: @resource.model_class.model_name.human), resource_new_path(@resource.class), variant: :primary)
      end

      # Standalone actions (no record selection needed) shown on the index header.
      def render_standalone_actions
        return unless authorized_to?(:act_on, @resource.model_class, policy_class: policy_class)

        actions = @resource.actions_for(view: :index).select(&:standalone?)
        return if actions.empty?

        render_actions_menu(actions, bulk: false)
      end

      # Bulk actions: an empty form (referenced by row checkboxes via the HTML `form`
      # attribute) plus an "Actions" dropdown of the bulk-action triggers.
      def render_bulk_toolbar
        return unless bulk?

        form(id: BULK_FORM_ID, method: "get")

        div(class: "flex items-center justify-end gap-2 mb-4") do
          span(class: "text-sm text-muted-foreground") { rua_t("index.with_selected") }
          render_actions_menu(bulk_actions, bulk: true, form_id: BULK_FORM_ID)
        end
      end

      def render_table
        render RubyUI::Table.new do
          render RubyUI::TableHeader.new do
            render RubyUI::TableRow.new do
              render RubyUI::TableHead.new(class: "w-10") { select_all_checkbox } if bulk?
              fields.each do |field|
                render RubyUI::TableHead.new { field.name }
              end
              render RubyUI::TableHead.new(class: "text-right") { rua_t("index.actions") }
            end
          end

          render RubyUI::TableBody.new do
            if @records.empty?
              render RubyUI::TableRow.new do
                render RubyUI::TableCell.new(colspan: column_count, class: "text-center text-muted-foreground py-8") { rua_t("index.empty") }
              end
            else
              @records.each { |record| render_row(record) }
            end
          end
        end
      end

      def column_count
        fields.size + 1 + (bulk? ? 1 : 0)
      end

      # Hidden until the JS reveals it (progressive enhancement).
      def select_all_checkbox
        render RubyUI::Checkbox.new(
          hidden: true,
          data: {rua__bulk_select_target: "selectAll", action: "change->rua--bulk-select#toggleAll"}
        )
      end

      def row_attrs(record)
        return {} unless RubyUIAdmin.configuration.click_row_to_view_record

        {
          class: "cursor-pointer",
          data: {
            controller: "rua--row-link",
            action: "click->rua--row-link#navigate",
            rua__row_link_url_value: resource_show_path(@resource.class, record)
          }
        }
      end

      def render_row(record)
        render RubyUI::TableRow.new(**row_attrs(record)) do
          if bulk?
            render RubyUI::TableCell.new do
              render RubyUI::Checkbox.new(
                name: "record_ids[]",
                value: record.id,
                form: BULK_FORM_ID,
                data: {rua_row_select: true}
              )
            end
          end

          fields.each_with_index do |field, index|
            render RubyUI::TableCell.new(class: ("font-medium" if index.zero?)) do
              link = field.link_to_record? ? resource_show_path(@resource.class, record) : nil
              render RubyUIAdmin::Views::FieldValue.new(field: field, record: record, link: link)
            end
          end

          render RubyUI::TableCell.new(class: "text-right whitespace-nowrap") do
            render_row_actions(record)
          end
        end
      end

      def render_row_actions(record)
        cfg = @resource.class.row_controls_config || {}
        placement = (cfg[:placement] == :left) ? "justify-start" : "justify-end"
        modes = [("float" if cfg[:float]), ("hover" if cfg[:show_on_hover])].compact.join(" ")
        data = modes.empty? ? {} : {rua_row_controls: modes}

        div(class: "inline-flex items-center gap-2 #{placement}", data: data) do
          render_row_controls(record)

          label = rua_t("actions.show")
          a(href: resource_show_path(@resource.class, record), title: label, aria_label: label,
            class: "inline-flex p-1 text-muted-foreground hover:text-foreground transition-colors") do
            render RubyUIAdmin::UI::Icon.new(:eye)
          end

          if authorized_to?(:update, record, policy_class: policy_class)
            label = rua_t("actions.edit")
            a(href: resource_edit_path(@resource.class, record), title: label, aria_label: label,
              class: "inline-flex p-1 text-muted-foreground hover:text-foreground transition-colors") do
              render RubyUIAdmin::UI::Icon.new(:pencil)
            end
          end

          if authorized_to?(:destroy, record, policy_class: policy_class)
            render_delete_button(record)
          end
        end
      end

      # Resource `self.row_controls = ->(record) { ... }` — extra per-row buttons/links.
      # Evaluated in this component (Phlex methods, `control_link`, route helpers available).
      def render_row_controls(record)
        controls = @resource.class.row_controls
        return if controls.nil?

        instance_exec(record, &controls)
      end

      def render_delete_button(record)
        form(action: resource_show_path(@resource.class, record), method: "post", class: "inline") do
          input(type: "hidden", name: "_method", value: "delete")
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          # `rua--confirm#request` opens the shared AlertDialog before submitting (JS); without
          # JS the form submits directly. The message names the record being deleted.
          label = rua_t("actions.destroy")
          button(
            type: "submit",
            title: label,
            aria_label: label,
            data: {
              action: "click->rua--confirm#request",
              rua__confirm_message_param: rua_t("confirm.destroy", model: @resource.record_title(record)),
              rua__confirm_heading_param: rua_t("confirm.destroy_title")
            },
            class: "inline-flex p-1 text-destructive hover:text-destructive/80 transition-colors"
          ) { render RubyUIAdmin::UI::Icon.new(:trash) }
        end
      end

      def render_scope_tabs
        scopes = @scopes.select { |scope| scope.visible?(user: RubyUIAdmin::Current.user) }
        return if scopes.empty?

        base = resource_index_path(@resource.class)

        nav(class: "flex items-center gap-1 mb-4 border-b border-border") do
          unless @remove_scope_all
            scope_tab(rua_t("index.all"), "#{base}?scope=all", active: @current_scope_key.nil?)
          end
          scopes.each do |scope|
            scope_tab(scope.name, "#{base}?scope=#{scope.key}", active: @current_scope_key == scope.key, title: scope.description)
          end
        end
      end

      def scope_tab(label, href, active:, title: nil)
        state = active ? "border-primary text-foreground" : "border-transparent text-muted-foreground hover:text-foreground"
        a(href: href, title: title, class: "px-3 py-2 -mb-px border-b-2 text-sm font-medium #{state}") { label }
      end

      def render_filter_bar
        render RubyUIAdmin::Views::FilterBar.new(
          filters: @filters,
          values: @filter_values,
          action_path: resource_index_path(@resource.class),
          scope_param: @scope_param
        )
      end

      def countless_pagy?
        defined?(Pagy::Countless) && @pagy.is_a?(Pagy::Countless)
      end

      def render_pagination
        return if @pagy.nil?
        # Countless has no total `pages`; render prev/next only.
        return if countless_pagy? ? !(@pagy.prev || @pagy.next) : @pagy.pages <= 1

        base = resource_index_path(@resource.class)
        render RubyUIAdmin::UI::Pagination.new(
          pagy: @pagy,
          countless: countless_pagy?,
          url_for_page: ->(page) { "#{base}?#{(@query_params || {}).merge("page" => page).to_query}" }
        )
      end
    end
  end
end
