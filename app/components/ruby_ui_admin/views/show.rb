# frozen_string_literal: true

module RubyUIAdmin
  module Views
    class Show < Base
      include StructureRenderer
      include ShowFields
      include ActionsMenu

      def initialize(resource:, record:)
        @resource = resource
        @record = record
      end

      def page_title
        "#{@resource.record_title(@record)} · #{RubyUIAdmin.configuration.app_name}"
      end

      def content
        render_header
        # `space-y-6` separates the structure's top-level sections (the fields card, panels
        # and tab groups) so they aren't glued together — mirrors the form's `space-y-6`.
        div(class: "space-y-6") do
          render_structure(@resource.field_structure(view: :show))
        end
      end

      # Lazy tabs (config): non-active show tabs fetch their content when first opened.
      def lazy_tabs?
        RubyUIAdmin.configuration.lazy_tabs
      end

      # URL a lazy tab fetches — the show path with the tab's flat index and `fragment=1`,
      # so only that tab's structure is rendered (and its queries run) on demand.
      def tab_fragment_url(flat_index)
        "#{resource_show_path(@resource.class, @record)}?tab=#{flat_index}&fragment=1"
      end

      private

      def policy_class
        @resource.class.authorization_policy
      end

      def render_header
        div(class: "flex items-center justify-between mb-6") do
          div do
            a(href: resource_index_path(@resource.class), class: "text-sm text-muted-foreground hover:underline") { "← #{@resource.navigation_label}" }
            h1(class: "text-2xl font-semibold tracking-tight mt-1") { @resource.record_title(@record).to_s }
          end

          div(class: "flex items-center gap-2") do
            render_record_actions

            if authorized_to?(:update, @record, policy_class: policy_class)
              a(
                href: resource_edit_path(@resource.class, @record),
                class: "inline-flex items-center h-9 px-4 rounded-md border border-input bg-background text-sm font-medium shadow-sm hover:bg-accent"
              ) { rua_t("actions.edit") }
            end
          end
        end
      end

      # Actions available for this single record, shown on the show view. Collapsed into the
      # searchable Combobox (same as the index) so many actions don't sprawl across the header.
      def render_record_actions
        return unless authorized_to?(:act_on, @record, policy_class: policy_class)

        actions = @resource.actions_for(view: :show, record: @record)
        return if actions.empty?

        render_actions_menu(actions, record_ids: [@record.id])
      end
    end
  end
end
