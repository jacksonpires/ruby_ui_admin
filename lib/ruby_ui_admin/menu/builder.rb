# frozen_string_literal: true

module RubyUIAdmin
  module Menu
    # A leaf linking to a resource's index. Carries the resolved resource so the view
    # can build the path through the dynamic routes.
    ResourceItem = Struct.new(:resource, :label, keyword_init: true) do
      def type = :resource
    end

    # A leaf linking to an arbitrary path.
    LinkItem = Struct.new(:label, :path, keyword_init: true) do
      def type = :link
    end

    # A leaf linking to a dashboard.
    DashboardItem = Struct.new(:dashboard, :label, keyword_init: true) do
      def type = :dashboard
    end

    # A titled group of items.
    SectionItem = Struct.new(:label, :icon, :items, keyword_init: true) do
      def type = :section
    end

    # Evaluates a `config.main_menu` block into a tree of menu items. The block is
    # instance_exec'd against a Builder, so `section`/`resource`/`link`/... are DSL calls.
    #
    #   config.main_menu = -> do
    #     section "Tables", icon: "table" do
    #       resource :user
    #       resource :buyer, label: "Buyers"
    #       link "Docs", "https://example.com"
    #     end
    #   end
    class Builder
      def self.build(&block)
        builder = new
        builder.instance_exec(&block)
        builder.items
      end

      attr_reader :items

      def initialize
        @items = []
      end

      def section(label = nil, icon: nil, &block)
        children = self.class.build(&block)
        @items << SectionItem.new(label: label, icon: icon, items: children)
      end
      alias_method :group, :section

      def resource(name, label: nil, **)
        resource = RubyUIAdmin.resource_manager.find_by_route_key(name.to_s)
        @items << ResourceItem.new(resource: resource, label: label) if resource
      end
      alias_method :resources, :resource

      def link(label, path = nil, **args)
        @items << LinkItem.new(label: label, path: path || args[:path])
      end
      alias_method :link_to, :link

      def dashboard(id, label: nil)
        dash = RubyUIAdmin.dashboard_manager.dashboards.find { |d| d.id.to_s == id.to_s }
        @items << DashboardItem.new(dashboard: dash, label: label) if dash
      end

      def all_resources(except: [])
        excluded = Array(except).map(&:to_s)
        RubyUIAdmin.resource_manager.navigation_resources.each do |rc|
          next if excluded.include?(rc.route_key)

          @items << ResourceItem.new(resource: rc, label: nil)
        end
      end

      def all_dashboards(except: [])
        excluded = Array(except).map(&:to_s)
        RubyUIAdmin.dashboard_manager.dashboards.each do |dash|
          next if excluded.include?(dash.id.to_s)

          @items << DashboardItem.new(dashboard: dash, label: nil)
        end
      end

      # Available inside the menu block.
      def current_user = RubyUIAdmin::Current.user
      def params = RubyUIAdmin::Current.params
    end
  end
end
