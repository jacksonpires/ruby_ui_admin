# frozen_string_literal: true

module RubyUIAdmin
  module UI
    # Orchestrates RubyUI's Pagination primitives (PaginationContent / PaginationItem /
    # PaginationEllipsis) from a Pagy instance: numbered page links with gaps, plus
    # Previous/Next. In countless mode (no total) it shows Previous/Next only.
    class Pagination < Base
      def initialize(pagy:, url_for_page:, countless: false, **attrs)
        @pagy = pagy
        @url_for_page = url_for_page
        @countless = countless
        super(**attrs)
      end

      def view_template
        nav(**attrs) do
          render PaginationContent.new do
            render_edge(:prev)
            render_series unless @countless
            render_edge(:next)
          end
        end
      end

      private

      def default_attrs
        {aria: {label: "pagination"}, role: "navigation", class: "flex w-full justify-end py-4"}
      end

      # Pagy#series yields page numbers (Integer), the current page (String) and `:gap`.
      def render_series
        @pagy.series.each do |item|
          if item == :gap
            render PaginationEllipsis.new
          elsif item.is_a?(String)
            render(PaginationItem.new(href: @url_for_page.call(item), active: true)) { item }
          else
            render(PaginationItem.new(href: @url_for_page.call(item))) { item.to_s }
          end
        end
      end

      def render_edge(direction)
        page = (direction == :prev) ? @pagy.prev : @pagy.next
        item_attrs = page ? {href: @url_for_page.call(page)} : {href: "#", class: "pointer-events-none opacity-50"}
        render(PaginationItem.new(**item_attrs)) { edge_content(direction) }
      end

      def edge_content(direction)
        if direction == :prev
          render RubyUIAdmin::UI::Icon.new(:chevron_left)
          plain I18n.t("ruby_ui_admin.pagination.previous")
        else
          plain I18n.t("ruby_ui_admin.pagination.next")
          render RubyUIAdmin::UI::Icon.new(:chevron_right)
        end
      end
    end
  end
end
