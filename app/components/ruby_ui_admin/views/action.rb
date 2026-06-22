# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Full-page confirmation/form for a custom action (no-JS fallback for the modal).
    class Action < Base
      def initialize(resource:, action:, action_id:, record_ids:)
        @resource = resource
        @action = action
        @action_id = action_id
        @record_ids = record_ids
      end

      def page_title
        "#{@action.name} · #{RubyUIAdmin.configuration.app_name}"
      end

      def content
        div(class: "mb-6") do
          a(href: resource_index_path(@resource.class), class: "text-sm text-muted-foreground hover:underline") { "← #{@resource.navigation_label}" }
          h1(class: "text-2xl font-semibold tracking-tight mt-1") { @action.name }
        end

        render RubyUI::Card.new(class: "max-w-2xl") do
          render RubyUI::CardContent.new(class: "pt-6") do
            render RubyUIAdmin::Views::ActionForm.new(
              resource: @resource,
              action: @action,
              action_id: @action_id,
              record_ids: @record_ids
            )
          end
        end
      end
    end
  end
end
