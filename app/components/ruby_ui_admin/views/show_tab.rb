# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Renders a single show tab's content as a standalone fragment (no page chrome), fetched
    # lazily by the JS when the tab is first opened. `tab_index` is the tab's flat position
    # across all tab groups on the show view — the same index the full page assigned.
    class ShowTab < Phlex::HTML
      include RubyUIAdmin::UI
      include RailsHelpers
      include PathHelpers
      include Translation
      include StructureRenderer
      include ShowFields

      def initialize(resource:, record:, tab_index:)
        @resource = resource
        @record = record
        @tab_index = tab_index
      end

      def view_template
        tab = flat_tabs[@tab_index]
        return if tab.nil?

        # Wrapped in the matching `<turbo-frame>` so the lazy frame on the show page swaps this in.
        # `target="_top"` so links/forms inside the tab break out of the frame (else Turbo renders
        # "Content missing" navigating within the frame to a page that has no matching frame).
        tag(:turbo_frame, id: "rua-tab-frame-#{@tab_index}", target: "_top") do
          render_tab_content(tab)
        end
      end

      private

      # Walks the show structure in the same depth-first order the full page renders, collecting
      # every tab so `@tab_index` maps to the same tab the page's flat counter assigned.
      def flat_tabs
        tabs = []
        collect_tabs(@resource.field_structure(view: :show), tabs)
        tabs
      end

      def collect_tabs(items, acc)
        items.each do |item|
          if item.is_a?(RubyUIAdmin::Structure::Panel)
            collect_tabs(item.items, acc)
          elsif item.is_a?(RubyUIAdmin::Structure::TabGroup)
            item.tabs.each do |tab|
              acc << tab
              collect_tabs(tab.items, acc)
            end
          end
        end
      end
    end
  end
end
