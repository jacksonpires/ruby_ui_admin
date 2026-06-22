# frozen_string_literal: true

module RubyUIAdmin
  module UI
    # Inline Lucide icons (lucide.dev, ISC license) — vendored as SVG paths so the gem
    # needs no icon dependency. Add entries to `render_paths` as needed.
    #
    #   render RubyUIAdmin::UI::Icon.new(:eye)
    #   render RubyUIAdmin::UI::Icon.new(:trash, class: "size-5")
    class Icon < Base
      def initialize(name, **attrs)
        @name = name.to_sym
        super(**attrs)
      end

      def view_template
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          viewbox: "0 0 24 24",
          fill: "none",
          stroke: "currentColor",
          stroke_width: "2",
          stroke_linecap: "round",
          stroke_linejoin: "round",
          **attrs
        ) { |s| render_paths(s) }
      end

      private

      def render_paths(s)
        case @name
        when :eye # lucide: eye
          s.path(d: "M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0")
          s.circle(cx: "12", cy: "12", r: "3")
        when :pencil # lucide: square-pen
          s.path(d: "M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7")
          s.path(d: "M18.375 2.625a1 1 0 0 1 3 3l-9.013 9.014a2 2 0 0 1-.853.505l-2.873.84a.5.5 0 0 1-.62-.62l.84-2.873a2 2 0 0 1 .506-.852z")
        when :trash # lucide: trash-2
          s.path(d: "M3 6h18")
          s.path(d: "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2")
          s.line(x1: "10", x2: "10", y1: "11", y2: "17")
          s.line(x1: "14", x2: "14", y1: "11", y2: "17")
        when :chevron_left # lucide: chevron-left
          s.path(d: "m15 18-6-6 6-6")
        when :chevron_right # lucide: chevron-right
          s.path(d: "m9 18 6-6-6-6")
        when :chevron_down # lucide: chevron-down
          s.path(d: "m6 9 6 6 6-6")
        when :circle # lucide: circle (generic leaf marker)
          s.circle(cx: "12", cy: "12", r: "10")
        when :layout_dashboard # lucide: layout-dashboard
          s.rect(width: "7", height: "9", x: "3", y: "3", rx: "1")
          s.rect(width: "7", height: "5", x: "14", y: "3", rx: "1")
          s.rect(width: "7", height: "9", x: "14", y: "12", rx: "1")
          s.rect(width: "7", height: "5", x: "3", y: "16", rx: "1")
        when :link # lucide: link
          s.path(d: "M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71")
          s.path(d: "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71")
        when :log_out # lucide: log-out
          s.path(d: "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4")
          s.polyline(points: "16 17 21 12 16 7")
          s.line(x1: "21", x2: "9", y1: "12", y2: "12")
        when :download # lucide: download
          s.path(d: "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4")
          s.polyline(points: "7 10 12 15 17 10")
          s.line(x1: "12", x2: "12", y1: "15", y2: "3")
        when :file # lucide: file
          s.path(d: "M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z")
          s.path(d: "M14 2v4a2 2 0 0 0 2 2h4")
        end
      end

      def default_attrs
        {class: "size-4", aria_hidden: "true"}
      end
    end
  end
end
