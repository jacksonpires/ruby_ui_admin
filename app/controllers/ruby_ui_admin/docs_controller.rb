# frozen_string_literal: true

module RubyUIAdmin
  # In-app documentation browser. Renders the gem's bundled `docs/*.md` files as HTML at
  # `<mount>/docs`. Availability is controlled by `config.docs_enabled` (default `:local`, i.e.
  # development/test only). In local environments it's open (no auth) for convenience; in any other
  # environment (e.g. production, when explicitly enabled) it runs behind the admin's
  # `authenticate_admin!` gate.
  class DocsController < ApplicationController
    skip_before_action :authenticate_admin!, if: -> { Rails.env.local? }

    # Root of the gem's Markdown documentation.
    DOCS_ROOT = RubyUIAdmin::Engine.root.join("docs").freeze

    before_action :ensure_docs_enabled!

    def show
      rel = resolve_relative_path(params[:path])
      return head(:not_found) unless rel

      abs = File.expand_path(rel, DOCS_ROOT)
      return head(:not_found) unless safe_doc_path?(abs)

      source = File.read(abs)
      html = render_markdown(source, current_dir: File.dirname(rel))

      render Views::Docs.new(
        body_html: html,
        title: doc_title(source) || humanize_slug(slug_for(rel)),
        nav_groups: nav_groups,
        current_slug: slug_for(rel)
      )
    rescue MissingDocsDependency => e
      render Views::Docs.new(
        body_html: dependency_help_html(e.message),
        title: "Documentation",
        nav_groups: [],
        current_slug: nil
      )
    end

    private

    def ensure_docs_enabled!
      head :not_found unless RubyUIAdmin.configuration.docs_enabled?
    end

    # Maps a URL path segment to a `docs/`-relative `.md` file. Returns nil for anything that
    # isn't a plain Markdown file (defense in depth alongside `safe_doc_path?`).
    def resolve_relative_path(path)
      slug = path.presence || "README"
      slug = slug.delete_suffix(".md")
      return nil if slug.include?("\0")

      "#{slug}.md"
    end

    # True only when `abs` is an existing `.md` file inside DOCS_ROOT (blocks `../` traversal).
    def safe_doc_path?(abs)
      root = DOCS_ROOT.to_s
      abs.start_with?("#{root}/") && abs.end_with?(".md") && File.file?(abs)
    end

    def slug_for(rel)
      rel.delete_suffix(".md")
    end

    # ---- Markdown ----------------------------------------------------------------------------

    def render_markdown(text, current_dir:)
      load_markdown_deps!

      # No `syntax_highlighter`: kramdown still emits `<pre><code class="language-…">` for fenced
      # blocks (styled by the view's CSS). We skip Rouge on purpose — its kramdown integration uses
      # a deprecated formatter that warns once per code block, flooding the dev log.
      html = Kramdown::Document.new(text, input: "GFM", hard_wrap: false, auto_ids: true).to_html
      rewrite_internal_links(html, current_dir)
    end

    def load_markdown_deps!
      require "kramdown"
      require "kramdown-parser-gfm"
    rescue LoadError
      raise MissingDocsDependency, "kramdown"
    end

    # Rewrites relative `*.md` links so they point at the docs route instead of 404-ing.
    # Absolute (http), anchor-only, and mailto links are left untouched.
    def rewrite_internal_links(html, current_dir)
      fragment = Nokogiri::HTML5.fragment(html)

      fragment.css("a[href]").each do |node|
        href = node["href"]
        next if href.blank? || href.match?(%r{\A(?:[a-z]+:|//|/|#)})

        path, anchor = href.split("#", 2)
        next unless path&.end_with?(".md")

        slug = resolve_link_slug(path, current_dir)
        new_href = doc_href(slug)
        new_href += "##{anchor}" if anchor.present?
        node["href"] = new_href
      end

      fragment.to_html
    end

    # Resolves a relative `.md` link (e.g. `../fields/overview.md`) against the current doc's
    # directory, returning a clean `docs/`-relative slug.
    def resolve_link_slug(path, current_dir)
      base = current_dir == "." ? "/" : "/#{current_dir}"
      File.expand_path(path, base).delete_prefix("/").delete_suffix(".md")
    end

    def doc_href(slug)
      slug == "README" ? docs_path : doc_path(path: slug)
    end

    # ---- Navigation --------------------------------------------------------------------------

    def nav_groups
      entries = Dir.glob(DOCS_ROOT.join("**/*.md")).sort.map do |abs|
        rel = Pathname.new(abs).relative_path_from(DOCS_ROOT).to_s
        slug = slug_for(rel)
        {
          slug: slug,
          title: doc_title(File.read(abs)) || humanize_slug(slug),
          href: doc_href(slug),
          group: rel.include?("/") ? rel.split("/").first : nil
        }
      end

      root = entries.select { |e| e[:group].nil? }
      grouped = entries.reject { |e| e[:group].nil? }.group_by { |e| e[:group] }

      result = []
      result << {label: nil, items: root} if root.any?
      grouped.sort.each { |dir, items| result << {label: humanize_slug(dir), items: items} }
      result
    end

    # ---- Helpers -----------------------------------------------------------------------------

    # The first level-1 heading of a Markdown document, if any.
    def doc_title(source)
      source[/^\#\s+(.+)$/, 1]&.strip
    end

    def humanize_slug(slug)
      slug.split("/").last.tr("-_", " ").split.map(&:capitalize).join(" ")
    end

    def dependency_help_html(gem_name)
      <<~HTML
        <h1>Documentation viewer needs a Markdown renderer</h1>
        <p>Add these to your app's <code>:development</code> group and <code>bundle install</code>:</p>
        <pre><code>gem "kramdown"
        gem "kramdown-parser-gfm"</code></pre>
        <p>(Missing: <code>#{ERB::Util.html_escape(gem_name)}</code>.)</p>
      HTML
    end

    # Raised when the Markdown gems aren't installed in the host app.
    class MissingDocsDependency < StandardError; end
  end
end
