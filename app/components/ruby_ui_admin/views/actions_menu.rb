# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Shared by Index and Show: collapses a set of action triggers into RubyUI's Combobox
    # (searchable popover) so the actions never wrap/sprawl across the header.
    module ActionsMenu
      # Each action is a Combobox item (clickable, opens its modal and closes the popover). The
      # modals are rendered after the combobox (outside the popover) so closing it doesn't hide
      # an open modal. `bulk:` ties triggers to the bulk-selection form (`form_id`); `record_ids:`
      # scopes them to specific records (the single-record show view).
      def render_actions_menu(actions, bulk: false, form_id: nil, record_ids: [])
        render RubyUI::Combobox.new do
          render RubyUI::ComboboxTrigger.new(placeholder: rua_t("index.actions"))
          render RubyUI::ComboboxPopover.new do
            render RubyUI::ComboboxSearchInput.new(placeholder: rua_t("index.search"))
            render RubyUI::ComboboxList.new do
              render(RubyUI::ComboboxEmptyState.new) { rua_t("index.no_results") }
              actions.each do |action|
                render RubyUI::ComboboxItem.new do
                  render RubyUIAdmin::Views::ActionTrigger.new(resource: @resource, action: action, record_ids: record_ids, bulk: bulk, form_id: form_id, part: :trigger, as_menu_item: true)
                end
              end
            end
          end
        end

        actions.each do |action|
          render RubyUIAdmin::Views::ActionTrigger.new(resource: @resource, action: action, record_ids: record_ids, bulk: bulk, form_id: form_id, part: :dialog)
        end
      end
    end
  end
end
