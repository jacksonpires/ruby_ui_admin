# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Standalone, self-contained page for the dev-only docs browser. Deliberately does NOT use the
    # admin layout or the host's RubyUI/Tailwind assets — it ships its own minimal CSS so it renders
    # correctly even in a freshly-installed host where the admin's styling isn't wired up yet.
    class Docs < Phlex::HTML
      def initialize(body_html:, title:, nav_groups:, current_slug:)
        @body_html = body_html
        @title = title
        @nav_groups = nav_groups
        @current_slug = current_slug
      end

      def view_template
        doctype
        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { "#{@title} · RubyUI Admin docs" }
            style { raw(safe(STYLES)) }
          end
          body do
            div(class: "rua-docs") do
              render_sidebar
              main(class: "rua-docs-main") do
                article(class: "rua-prose") { raw(safe(@body_html)) }
              end
            end
          end
        end
      end

      private

      def render_sidebar
        nav(class: "rua-docs-nav") do
          div(class: "rua-docs-brand") { "RubyUI Admin · Docs" }
          @nav_groups.each do |group|
            div(class: "rua-docs-group") do
              h3 { group[:label] } if group[:label]
              ul do
                group[:items].each do |item|
                  li do
                    a(href: item[:href], class: item[:slug] == @current_slug ? "active" : nil) { item[:title] }
                  end
                end
              end
            end
          end
        end
      end

      STYLES = <<~CSS
        *, *::before, *::after { box-sizing: border-box; }
        body { margin: 0; font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color: #1f2328; background: #fff; }
        .rua-docs { display: flex; min-height: 100vh; align-items: stretch; }
        .rua-docs-nav { flex: 0 0 17rem; border-right: 1px solid #e5e7eb; background: #f9fafb; padding: 1.25rem 1rem; overflow-y: auto; position: sticky; top: 0; height: 100vh; }
        .rua-docs-brand { font-weight: 600; font-size: .9rem; margin-bottom: 1rem; color: #111827; }
        .rua-docs-group { margin-bottom: 1rem; }
        .rua-docs-group h3 { font-size: .7rem; text-transform: uppercase; letter-spacing: .05em; color: #6b7280; margin: .75rem 0 .35rem; }
        .rua-docs-nav ul { list-style: none; margin: 0; padding: 0; }
        .rua-docs-nav li { margin: 0; }
        .rua-docs-nav a { display: block; padding: .25rem .5rem; border-radius: .375rem; color: #374151; text-decoration: none; font-size: .85rem; }
        .rua-docs-nav a:hover { background: #eef2ff; color: #1d4ed8; }
        .rua-docs-nav a.active { background: #e0e7ff; color: #1d4ed8; font-weight: 600; }
        .rua-docs-main { flex: 1 1 auto; min-width: 0; display: flex; justify-content: center; padding: 2rem 2.5rem 4rem; }
        .rua-prose { width: 100%; max-width: 48rem; line-height: 1.65; }
        .rua-prose h1, .rua-prose h2, .rua-prose h3, .rua-prose h4 { line-height: 1.25; font-weight: 600; margin-top: 1.75em; margin-bottom: .6em; }
        .rua-prose h1 { font-size: 1.9rem; margin-top: 0; }
        .rua-prose h2 { font-size: 1.45rem; padding-bottom: .3em; border-bottom: 1px solid #e5e7eb; }
        .rua-prose h3 { font-size: 1.2rem; }
        .rua-prose p, .rua-prose ul, .rua-prose ol, .rua-prose blockquote, .rua-prose table { margin: 0 0 1em; }
        .rua-prose a { color: #1d4ed8; text-decoration: underline; text-underline-offset: 2px; }
        .rua-prose ul, .rua-prose ol { padding-left: 1.5em; }
        .rua-prose li { margin: .25em 0; }
        .rua-prose code { font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace; font-size: .875em; background: #f3f4f6; padding: .15em .35em; border-radius: .3em; }
        .rua-prose pre { background: #f6f8fa; border: 1px solid #e5e7eb; border-radius: .5rem; padding: 1rem; overflow-x: auto; }
        .rua-prose pre code { background: none; padding: 0; font-size: .85rem; }
        .rua-prose blockquote { border-left: 3px solid #d1d5db; padding: .1em 1em; color: #4b5563; background: #f9fafb; border-radius: 0 .375rem .375rem 0; }
        .rua-prose table { border-collapse: collapse; width: 100%; display: block; overflow-x: auto; font-size: .9rem; }
        .rua-prose th, .rua-prose td { border: 1px solid #e5e7eb; padding: .5em .75em; text-align: left; }
        .rua-prose th { background: #f9fafb; font-weight: 600; }
        .rua-prose img { max-width: 100%; }
        .rua-prose hr { border: none; border-top: 1px solid #e5e7eb; margin: 2em 0; }
      CSS
    end
  end
end
