# frozen_string_literal: true

module RubyUIAdmin
  module Views
    # Full-page layout/chrome for every admin screen. Subclasses implement `content`.
    class Base < Phlex::HTML
      include RubyUIAdmin::UI
      include RailsHelpers
      include PathHelpers
      include Translation

      def view_template
        doctype
        # `overflow-y: auto` keeps the admin scrollable even when the host's global CSS locks page
        # scroll (e.g. `html, body { overflow: hidden }` for a fixed-viewport app shell) — the admin
        # renders its own document, so it can't rely on the host layout's own scroll override.
        html(lang: "en", style: "overflow-y: auto") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { page_title }
            render_head_assets
          end
          # Turbo Drive is on (self-hosted, see render_head_assets) for SPA-style navigation — no
          # full-page reloads. `rua--confirm` manages the shared delete-confirmation AlertDialog.
          body(class: "min-h-screen bg-background text-foreground antialiased", data: {controller: "rua--confirm"}) do
            render RubyUI::SidebarWrapper.new do
              render_sidebar
              render RubyUI::SidebarInset.new do
                render_topbar
                main(class: "flex-1 min-w-0 p-6 lg:p-8") do
                  # `rua--dialog` manages the lazy action modals rendered anywhere in the page body.
                  div(data: {controller: "rua--dialog"}, class: "w-full max-w-7xl mx-auto") { content }
                end
              end
            end
            render_toaster
            render_confirm_dialog
          end
        end
      end

      # Overridden by subclasses.
      def content; end

      # Whether the current user is allowed to perform `rule` on `record`.
      def authorized_to?(rule, record, policy_class: nil)
        RubyUIAdmin::Services::AuthorizationService
          .new(RubyUIAdmin::Current.user, record, policy_class: policy_class)
          .allowed?(rule)
      end

      private

      def page_title
        RubyUIAdmin.configuration.app_name
      end

      def navigation_resources
        RubyUIAdmin.resource_manager.navigation_resources
      end

      # Top bar inside the inset: holds the sidebar trigger (toggles the desktop icon-rail
      # collapse and opens the mobile drawer). Kept minimal — no app-name/user chrome.
      def render_topbar
        header(class: "sticky top-0 z-10 flex h-14 shrink-0 items-center gap-2 border-b bg-background px-4") do
          render RubyUI::SidebarTrigger.new(class: "-ml-1")
        end
      end

      # The RubyUI Sidebar: fixed/expanded by default, collapses to an icon rail on user
      # action (persisted via cookie), and becomes a drawer on mobile (<768px).
      def render_sidebar
        render RubyUI::Sidebar.new(collapsible: :icon, open: sidebar_open?) do
          render RubyUI::SidebarHeader.new do
            div(class: "flex items-center gap-2 px-2 py-1.5 font-semibold") do
              render RubyUIAdmin::UI::Icon.new(:layout_dashboard, class: "size-5 shrink-0")
              span(class: "truncate group-data-[collapsible=icon]:hidden") { RubyUIAdmin.configuration.app_name }
            end
          end

          render RubyUI::SidebarContent.new do
            if (menu = main_menu_items)
              render_menu(menu)
            else
              render_auto_menu
            end
          end

          render_sidebar_footer

          render RubyUI::SidebarRail.new
        end
      end

      # Bottom of the sidebar: current user label + a sign-out item. Rendered only when
      # `config.sign_out_path_name` is set (resolved via the host's `main_app` routes).
      def render_sidebar_footer
        path_name = RubyUIAdmin.configuration.sign_out_path_name
        return if path_name.blank?

        render RubyUI::SidebarFooter.new do
          render RubyUI::SidebarMenu.new do
            if (label = current_user_label)
              render RubyUI::SidebarMenuItem.new do
                div(class: "flex items-center gap-2 px-2 py-1.5 text-xs text-muted-foreground truncate group-data-[collapsible=icon]:hidden") { plain label }
              end
            end

            render RubyUI::SidebarMenuItem.new do
              render_sign_out_button(path_name)
            end
          end
        end
      end

      def render_sign_out_button(path_name)
        action = main_app.public_send(path_name)
        method = (RubyUIAdmin.configuration.sign_out_method || :delete).to_s

        form(action: action, method: "post", class: "w-full") do
          input(type: "hidden", name: "_method", value: method)
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          render RubyUI::SidebarMenuButton.new(as: :button, type: "submit", title: rua_t("nav.sign_out")) do
            render RubyUIAdmin::UI::Icon.new(:log_out, class: "size-4 shrink-0")
            span(class: "truncate") { rua_t("nav.sign_out") }
          end
        end
      end

      # Best-effort label for the signed-in user (email → name → to_s).
      def current_user_label
        u = RubyUIAdmin::Current.user
        return nil unless u

        (u.respond_to?(:email) && u.email.presence) ||
          (u.respond_to?(:name) && u.name.presence) ||
          u.to_s
      end

      # Reads the persisted collapse state (set client-side by the sidebar controller) so
      # the server renders the same state and there's no flash on navigation.
      def sidebar_open?
        request.cookies["sidebar_state"] != "false"
      rescue
        true
      end

      # The curated menu tree, or nil when no `config.main_menu` is set (auto navigation).
      def main_menu_items
        block = RubyUIAdmin.configuration.main_menu
        return nil unless block

        RubyUIAdmin::Menu::Builder.build(&block)
      end

      # Curated menu: top-level leaves go into one group; each section becomes a group.
      def render_menu(items)
        leaves, sections = items.partition { |item| item.type != :section }
        render_leaf_group(leaves) if leaves.any?
        sections.each { |section| render_menu_section(section) }
      end

      def render_menu_section(section)
        render RubyUI::SidebarGroup.new do
          if section.label.present?
            render RubyUI::SidebarGroupLabel.new do
              render_menu_icon(section.icon)
              plain section.label.to_s
            end
          end
          leaves = section.items.reject { |item| item.type == :section }
          render RubyUI::SidebarMenu.new do
            leaves.each { |item| render_menu_leaf(item) }
          end
        end
        # Nested sections (rare) render as their own sibling groups.
        section.items.select { |item| item.type == :section }.each { |nested| render_menu_section(nested) }
      end

      # Auto navigation (no curated menu): a dashboards group (if any) + a resources group.
      def render_auto_menu
        dashboards = RubyUIAdmin.dashboard_manager.dashboards
        render_leaf_group(dashboards.map { |d| RubyUIAdmin::Menu::DashboardItem.new(dashboard: d) }) if dashboards.any?
        render_leaf_group(navigation_resources.map { |rc| RubyUIAdmin::Menu::ResourceItem.new(resource: rc) })
      end

      def render_leaf_group(leaves)
        render RubyUI::SidebarGroup.new do
          render RubyUI::SidebarMenu.new do
            leaves.each { |item| render_menu_leaf(item) }
          end
        end
      end

      def render_menu_leaf(item)
        href, label, icon = menu_leaf_attrs(item)
        return if href.nil?

        # Resource items stay active across the whole resource (index/show/new/edit/actions),
        # so the index path is treated as a prefix. Dashboards/links match the exact path only.
        active = current_path?(href, prefix: item.type == :resource)

        render RubyUI::SidebarMenuItem.new do
          render RubyUI::SidebarMenuButton.new(as: :a, href: href, title: label.to_s, active: active) do
            render RubyUIAdmin::UI::Icon.new(icon, class: "size-4 shrink-0")
            span(class: "truncate") { plain label.to_s }
          end
        end
      end

      # Returns [href, label, icon] for a leaf menu item, or nil href if unresolvable.
      def menu_leaf_attrs(item)
        case item.type
        when :resource
          [resource_index_path(item.resource), item.label || item.resource.navigation_label, :circle]
        when :dashboard
          [ruby_ui_admin.dashboard_path(dashboard_id: item.dashboard.id), item.label || item.dashboard.title, :layout_dashboard]
        when :link
          [item.path, item.label, :link]
        end
      end

      # Exact path match, or (when `prefix:`) any path nested under it — so a resource's nav
      # entry stays active on its show/new/edit/action pages, not just the index.
      def current_path?(href, prefix: false)
        path = href.to_s.split("?").first
        return false if path.nil? || path.empty?
        return true if request.path == path

        prefix && request.path.start_with?("#{path}/")
      rescue
        false
      end

      # Renders a menu section icon. A raw SVG/HTML string is rendered as-is; named icons
      # (e.g. "heroicons/outline/table-cells") need a host-provided SVG and are skipped.
      def render_menu_icon(icon)
        return if icon.nil? || icon.to_s.strip.empty?

        raw(safe(icon.to_s)) if icon.to_s.include?("<svg")
      end

      # Flash messages render through RubyUI's Toast component (Stimulus-driven). A
      # `<noscript>` fallback keeps them visible (as badges) when JS is off.
      def render_toaster
        messages = flash.to_hash

        render RubyUIAdmin::UI::ToastRegion.new(
          flash: messages,
          position: :bottom_right,
          close_button: true,
          duration: 5000
        )

        return if messages.empty?

        noscript do
          div(class: "fixed top-4 right-4 z-[100] flex flex-col gap-2") do
            messages.each do |type, message|
              next if message.blank?

              variant = %w[alert error].include?(type.to_s) ? :destructive : :success
              render RubyUI::Badge.new(variant: variant) { message.to_s }
            end
          end
        end
      end

      # Shared confirmation AlertDialog, driven by the `rua--confirm` Stimulus controller (on
      # <body>). A trigger (e.g. delete) opens it via `click->rua--confirm#request`. Without JS the
      # trigger's form submits directly (the action still works); with JS, this dialog confirms first.
      def render_confirm_dialog
        div(data: {rua__confirm_target: "dialog"}, hidden: true, class: "fixed inset-0 z-50 flex items-center justify-center p-4") do
          div(data: {action: "click->rua--confirm#cancel"}, class: "absolute inset-0 bg-black/50")
          div(role: "alertdialog", "aria-modal": "true", class: "relative z-10 w-full max-w-md rounded-xl border border-border bg-background shadow-lg p-6") do
            h2(data: {rua__confirm_target: "title"}, class: "text-lg font-semibold") { rua_t("confirm.title") }
            p(data: {rua__confirm_target: "message"}, class: "text-sm text-muted-foreground mt-2") { rua_t("confirm.message") }
            div(class: "flex items-center justify-end gap-3 mt-6") do
              render(RubyUI::Button.new(type: :button, variant: :outline, data: {action: "click->rua--confirm#cancel"})) { rua_t("confirm.cancel") }
              render(RubyUI::Button.new(type: :button, variant: :destructive, data: {action: "click->rua--confirm#confirm"})) { rua_t("confirm.confirm") }
            end
          end
        end
      end

      # The admin renders the host's RubyUI components, so the host owns the head assets — its
      # Tailwind build (CSS, incl. the RubyUI design tokens) and its bundler/importmap (JS that
      # registers the RubyUI Stimulus controllers and ours). The host supplies them via
      # `config.head_assets` (a proc evaluated in the Rails view context). When unset, no assets
      # are emitted (the page still renders; it just won't be styled/enhanced).
      def render_head_assets
        head_assets = RubyUIAdmin.configuration.head_assets
        return unless head_assets

        markup = view_context.instance_exec(&head_assets)
        raw(safe(markup.to_s)) if markup
      end
    end
  end
end
