# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Walks a resource's field structure (fields + panels + tabs) and renders it.
    # The includer defines `render_field(field)` to render a single field row/input.
    # Bare top-level fields are grouped into a default card.
    module StructureRenderer
      # `wrap_bare:` controls whether loose top-level fields get their own card. It's true
      # at the top level (so naked fields aren't unframed) and false inside a panel/tab —
      # which already provide a card — to avoid a redundant nested card layer.
      def render_structure(items, wrap_bare: true)
        buffer = []

        flush = lambda do
          next if buffer.empty?

          group = buffer.dup
          buffer.clear
          if wrap_bare
            render RubyUI::Card.new do
              render RubyUI::CardContent.new(class: "pt-6 space-y-4") do
                group.each { |field| render_field(field) }
              end
            end
          else
            group.each { |field| render_field(field) }
          end
        end

        items.each do |item|
          if item.is_a?(RubyUIAdmin::Fields::BaseField)
            buffer << item
          elsif item.is_a?(RubyUIAdmin::Structure::Panel)
            flush.call
            render_panel(item)
          elsif item.is_a?(RubyUIAdmin::Structure::TabGroup)
            flush.call
            render_tab_group(item)
          end
        end

        flush.call
      end

      private

      def render_panel(panel)
        render RubyUI::Card.new(class: "mb-6") do
          # Show the panel title, except when it merely repeats the name of the tab that
          # contains it — that's pure duplication (the tab bar already labels the section),
          # and the empty header would just push the content down. Distinct names still render.
          if panel.name && panel.name.to_s.strip != @enclosing_tab_name.to_s.strip
            render RubyUI::CardHeader.new do
              render RubyUI::CardTitle.new { panel.name }
            end
          end
          render RubyUI::CardContent.new(class: "pt-6 space-y-4") do
            render_structure(panel.items, wrap_bare: false)
          end
        end
      end

      # Tabs render as a progressive enhancement, driven by the `rua--tabs` Stimulus controller:
      #   * Without JS: the tab bar is hidden and the panels stack (each as a titled card).
      #   * With JS: the controller reveals the tab bar, hides the per-panel headings, and shows
      #     only the active panel. Keys are matched via `data-rua-tab` / `data-rua-tab-panel`.
      def render_tab_group(group)
        @tab_group_seq = (@tab_group_seq || 0) + 1
        base = "rua-tab-#{@tab_group_seq}"

        div(data: {controller: "rua--tabs"}, class: "mb-6") do
          nav(data: {rua__tabs_target: "nav"}, hidden: true, class: "flex items-center gap-1 border-b border-border mb-4") do
            group.tabs.each_with_index do |tab, index|
              button(
                type: "button",
                data: {rua__tabs_target: "tab", rua_tab: "#{base}-#{index}", action: "click->rua--tabs#show"},
                class: "px-3 py-2 -mb-px border-b-2 border-transparent text-sm font-medium text-muted-foreground hover:text-foreground"
              ) { tab.name }
            end
          end

          group.tabs.each_with_index do |tab, index|
            # Flat index across all tab groups on the page — the lazy fragment endpoint uses it
            # to locate this exact tab. Incremented for every tab (eager and lazy) so it stays
            # aligned with the controller's identical walk of the structure.
            flat_index = (@tab_flat_seq ||= -1) + 1
            @tab_flat_seq = flat_index
            # Only non-active tabs (index > 0 within their group) load lazily; the first tab is
            # the active one and always renders eagerly so there's no flash/spinner up front.
            lazy_url = (lazy_tabs? && index.positive?) ? tab_fragment_url(flat_index) : nil

            panel_data = {rua__tabs_target: "panel", rua_tab_panel: "#{base}-#{index}"}

            # The tab is just the switchable container — its children (panels) provide the
            # cards, so we don't wrap the tab body in its own Card (which caused a redundant
            # nested-panel layer). `wrap_bare: true` still cards loose fields inside a tab.
            div(data: panel_data, class: "space-y-4") do
              # Heading shown when stacked (no JS); the controller hides it since the tab bar
              # already labels the section.
              h3(data: {rua__tabs_target: "heading"}, class: "text-sm font-semibold uppercase tracking-wide text-muted-foreground") { tab.name }
              # Skip a description that merely repeats the tab name — it's pure duplication
              # (the tab bar already shows the name). Genuine, distinct descriptions still render.
              if tab.description.present? && tab.description.to_s.strip != tab.name.to_s.strip
                p(class: "text-sm text-muted-foreground") { tab.description }
              end

              if lazy_url
                render_lazy_tab_frame("rua-tab-frame-#{flat_index}", lazy_url)
              else
                render_tab_content(tab)
              end
            end
          end
        end
      end

      # Renders a tab's inner structure, tracking the enclosing tab name so a child panel named
      # identically to the tab can drop its redundant title (see render_panel).
      def render_tab_content(tab)
        prev_tab_name = @enclosing_tab_name
        @enclosing_tab_name = tab.name
        render_structure(tab.items, wrap_bare: true)
        @enclosing_tab_name = prev_tab_name
      end

      # A lazy `<turbo-frame loading="lazy">`: Turbo fetches `src` when the frame becomes visible
      # (i.e. when its tab is shown) and swaps in the matching frame from the response (ShowTab).
      # The spinner shows until then; without JS the <noscript> notice replaces it.
      # `target="_top"` so links/forms inside the tab content navigate the whole page (otherwise
      # they'd try to navigate within this frame and Turbo would render "Content missing" — the
      # target page has no matching frame id). It doesn't affect the frame's own `src` lazy load.
      def render_lazy_tab_frame(frame_id, src)
        tag(:turbo_frame, id: frame_id, loading: "lazy", src: src, target: "_top") do
          div(data: {rua_tab_spinner: true}, class: "flex items-center justify-center py-12") do
            div(class: "size-6 rounded-full border-2 border-muted border-t-foreground animate-spin", role: "status", aria_label: rua_t("tabs.loading"))
          end
          noscript { p(class: "text-sm text-muted-foreground py-4") { rua_t("tabs.requires_js") } }
        end
      end

      # Overridden by the Show view to enable lazy tab loading; eager everywhere else.
      def lazy_tabs? = false

      def tab_fragment_url(_flat_index) = nil
    end
  end
end
