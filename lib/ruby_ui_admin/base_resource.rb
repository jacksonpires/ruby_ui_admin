# frozen_string_literal: true

require "active_support/core_ext/class/attribute"
require "active_support/core_ext/string"
require "active_support/core_ext/object/blank"

module RubyUIAdmin
  # Base class for all resources. Provides the declarative resource DSL
  # (fields, panels, tabs, scopes, actions and filters).
  class BaseResource
    class_attribute :title, instance_accessor: false, default: :id
    class_attribute :includes, instance_accessor: false, default: []
    class_attribute :authorization_policy, instance_accessor: false, default: nil
    class_attribute :index_query, instance_accessor: false, default: nil
    class_attribute :index_controls, instance_accessor: false, default: nil
    class_attribute :visible_on_sidebar, instance_accessor: false, default: true
    class_attribute :record_selector, instance_accessor: false, default: true
    class_attribute :default_view_type, instance_accessor: false, default: :table
    class_attribute :description, instance_accessor: false, default: nil
    # When true, the index hides the "All" scope tab (use with a default scope).
    class_attribute :remove_scope_all, instance_accessor: false, default: false
    # Optional proc `->(record) { ... }` rendering extra per-row controls on the index.
    class_attribute :row_controls, instance_accessor: false, default: nil
    # Layout for the per-row controls cell: `{ placement: :left|:right, float: bool, show_on_hover: bool }`.
    class_attribute :row_controls_config, instance_accessor: false, default: {}
    # When true, the index paginates without a COUNT query (pagy countless) — for big tables.
    class_attribute :countless, instance_accessor: false, default: false

    class << self
      def model_class=(value)
        @model_class = value.is_a?(String) ? value.constantize : value
      end

      def model_class
        return @model_class if defined?(@model_class) && @model_class

        @model_class = derive_model_class
      end

      def derive_model_class
        name.to_s.demodulize.constantize
      rescue NameError
        nil
      end

      def abstract?
        self == RubyUIAdmin::BaseResource
      end

      # "buyer"
      def resource_name
        name.to_s.demodulize.underscore
      end

      # "buyers"
      def resource_name_plural
        resource_name.pluralize
      end

      # Route key used by the dynamic router and path helpers, e.g. "buyers".
      # Derived from the RESOURCE name (not the model) so multiple resources backed by the
      # same model get distinct routes. Override per-resource if needed.
      def route_key
        resource_name_plural
      end

      def singular_route_key
        resource_name
      end

      def navigation_label
        resource_name_plural.titleize
      end
    end

    attr_accessor :record, :view, :user, :params

    def initialize(record: nil, view: nil, user: nil, params: nil)
      @record = record
      @view = view
      @user = user
      @params = params
    end

    def hydrate(record: nil, view: nil, user: nil, params: nil)
      @record = record unless record.nil?
      @view = view unless view.nil?
      @user = user unless user.nil?
      @params = params unless params.nil?
      self
    end

    def model_class = self.class.model_class
    def route_key = self.class.route_key
    def singular_route_key = self.class.singular_route_key
    def resource_name = self.class.resource_name
    # Alias so resource DSL (e.g. field defaults/options evaluated eagerly) can use
    # `current_user`. `user` is set on hydrate.
    def current_user = user
    def navigation_label = self.class.navigation_label

    # ---- Fields DSL ----

    def field(id, as: :text, **options, &block)
      field_class = Fields.field_class_for(as)
      instance = field_class.new(id, resource: self, **options, &block)
      current_collector << instance
      instance
    end

    # Groups fields in a card-like panel. Accepts the name either positionally (`panel "X"`)
    # or as a keyword (`panel name: "X"`) for Avo compatibility.
    def panel(name = nil, **opts, &block)
      name = opts[:name] if name.nil?
      container = Structure::Panel.new(name)
      current_collector << container
      within(container.items, &block)
      container
    end

    # Declares a set of tabs. Use `tab` inside the block.
    def tabs(&block)
      group = Structure::TabGroup.new
      current_collector << group
      within(group.tabs, &block)
      group
    end

    # A single tab inside a `tabs` block.
    def tab(name, description: nil, &block)
      container = Structure::Tab.new(name, description: description)
      current_collector << container
      within(container.items, &block)
      container
    end

    def divider(**); end

    # Auto-declares fields from the model's database columns.
    #   discover_columns(only: %i[id name], except: %i[token])
    def discover_columns(only: nil, except: [])
      except = Array(except).map(&:to_sym)
      only = only && Array(only).map(&:to_sym)

      model_class.columns.each do |column|
        name = column.name.to_sym
        next if except.include?(name)
        next if only && !only.include?(name)
        next if name.to_s.end_with?("_id") && only.nil? # foreign keys -> use discover_associations

        field name, as: field_type_for_column(column, name)
      end
    end

    # Auto-declares fields from the model's associations.
    def discover_associations(only: nil, except: [])
      except = Array(except).map(&:to_sym)
      only = only && Array(only).map(&:to_sym)

      model_class.reflect_on_all_associations.each do |association|
        name = association.name
        next if except.include?(name)
        next if only && !only.include?(name)

        type = association_field_type(association)
        field name, as: type if type
      end
    end

    # Overridden by subclasses to declare fields.
    def fields; end

    # The structured item tree (fields + panels + tabs) for the given view.
    def field_structure(view: nil)
      build_items
      filter_item_tree(@root, view)
    end

    # Flat list of field leaves visible in the given view (used by the index,
    # param permitting and record filling). Filters by view visibility AND by
    # field-level authorization.
    def get_fields(view: nil)
      build_items
      leaves = flatten_fields(@root)
      leaves = leaves.select { |field| field.visible_in_view?(view) && field.visible?(view: view) && field_authorized?(field, view) } if view
      leaves
    end

    def find_field(id)
      get_fields.find { |field| field.id == id.to_sym }
    end

    # Applies field-level `default:` values to a new record (literal or proc).
    def apply_defaults(record)
      get_fields(view: :new).each do |field|
        next unless field.has_default?

        field.fill_value(record, field.default_value(record))
      end

      record
    end

    # Whether the current user may see this field in the given view.
    #
    # A field is visible unless the resource's policy explicitly defines a matching
    # rule that returns false. Candidate rules, most specific first:
    #   index -> index_<id>? ; show -> show_<id>? ; new -> new_<id>?/edit_<id>? ;
    #   edit -> edit_<id>? ; then the generic view_<id>? for any view.
    # An undefined rule means "no opinion" and the field stays visible (so enabling
    # explicit_authorization does NOT silently hide every unconfigured field).
    def field_authorized?(field, view)
      return true unless RubyUIAdmin.configuration.authorization_enabled?

      policy = self.class.authorization_policy
      return true if policy.nil?

      service = Services::AuthorizationService.new(user, @record, policy_class: policy)
      rule = candidate_field_rules(field.id, view).find { |candidate| service.defines_rule?(candidate) }
      return true if rule.nil?

      service.authorize_action(rule, record: @record, raise_exception: false)
    end

    # ---- Scopes DSL ----

    # `scope Klass` or `scope Klass, default: true` (mark default at attachment time).
    def scope(klass, **options)
      scope_items << {klass: klass, options: options}
    end

    def scope_items
      @scope_items ||= []
    end

    # Overridden by subclasses to declare named index scopes.
    def scopes; end

    def get_scopes
      @scope_items = []
      @remove_scope_all_called = false
      scopes
      scope_items.map do |entry|
        entry[:klass].new(params: params || {}, default_override: entry[:options][:default])
      end
    end

    # Callable inside `def scopes` to hide the "All" tab. The class
    # attribute `self.remove_scope_all = true` also works.
    def remove_scope_all
      @remove_scope_all_called = true
    end

    def remove_scope_all?
      get_scopes # ensures `scopes` ran (which may call `remove_scope_all`)
      @remove_scope_all_called || self.class.remove_scope_all
    end

    def scopes?
      get_scopes.any?
    end

    def find_scope(key)
      get_scopes.find { |scope| scope.key == key.to_s }
    end

    def default_scope_entry
      get_scopes.find(&:default?)
    end

    private

    COLUMN_TYPE_MAP = {
      string: :text,
      text: :textarea,
      integer: :number,
      float: :number,
      decimal: :number,
      boolean: :boolean,
      date: :date,
      datetime: :date_time,
      timestamp: :date_time,
      json: :code,
      jsonb: :code
    }.freeze

    NAME_TYPE_MAP = {
      "id" => :id,
      "email" => :text,
      "password" => :password,
      "password_digest" => :password
    }.freeze

    def field_type_for_column(column, name)
      return :id if name == :id
      return NAME_TYPE_MAP.fetch(name.to_s) if NAME_TYPE_MAP.key?(name.to_s)

      COLUMN_TYPE_MAP.fetch(column.type, :text)
    end

    def association_field_type(association)
      case association.macro
      when :belongs_to then :belongs_to
      when :has_one then :has_one
      when :has_many then :has_many
      when :has_and_belongs_to_many then :has_and_belongs_to_many
      end
    end

    def build_items
      @root = []
      @collector_stack = [@root]
      fields
      @root
    end

    def current_collector
      (@collector_stack ||= [(@root ||= [])]).last
    end

    def within(collection)
      @collector_stack.push(collection)
      yield if block_given?
    ensure
      @collector_stack.pop
    end

    def flatten_fields(items)
      items.flat_map do |item|
        if item.is_a?(Fields::BaseField)
          [item]
        elsif item.respond_to?(:items)
          flatten_fields(item.items)
        else
          []
        end
      end
    end

    # Candidate field-authorization rules for a field id in a given view, most
    # specific first, ending with the generic `view_<id>?`.
    def candidate_field_rules(id, view)
      case view&.to_sym
      when :index then [:"index_#{id}?", :"view_#{id}?"]
      when :show then [:"show_#{id}?", :"view_#{id}?"]
      when :new then [:"new_#{id}?", :"edit_#{id}?", :"view_#{id}?"]
      when :edit then [:"edit_#{id}?", :"view_#{id}?"]
      else [:"view_#{id}?"]
      end
    end

    # Returns a copy of the tree with field leaves filtered by view visibility and
    # field-level authorization.
    def filter_item_tree(items, view)
      items.each_with_object([]) do |item, result|
        if item.is_a?(Fields::BaseField)
          result << item if (view.nil? || item.visible_in_view?(view)) && item.visible?(view: view) && field_authorized?(item, view)
        elsif item.is_a?(Structure::TabGroup)
          # A child may be a Tab, or a bare field/panel placed directly
          # inside `tabs do`. Normalize each into [name, description, children] so bare
          # children become implicit tabs (labelled by the field/panel name).
          normalized = item.tabs.map do |child|
            if child.is_a?(Structure::Tab)
              [child.name, child.description, filter_item_tree(child.items, view)]
            elsif child.is_a?(Structure::Panel)
              [child.name, nil, filter_item_tree(child.items, view)]
            elsif child.is_a?(Fields::BaseField)
              keep = (view.nil? || child.visible_in_view?(view)) && child.visible?(view: view) && field_authorized?(child, view)
              [child.name, nil, keep ? [child] : []]
            else
              [nil, nil, []]
            end
          end
          kept = normalized.reject { |(_name, _desc, children)| children.empty? }
          unless kept.empty?
            group = Structure::TabGroup.new
            kept.each do |(name, description, children)|
              new_tab = Structure::Tab.new(name, description: description)
              children.each { |child| new_tab.items << child }
              group.tabs << new_tab
            end
            result << group
          end
        elsif item.is_a?(Structure::Panel)
          children = filter_item_tree(item.items, view)
          unless children.empty?
            panel = Structure::Panel.new(item.name)
            children.each { |child| panel.items << child }
            result << panel
          end
        end
      end
    end

    public

    # ---- Actions DSL ----

    def action(klass, **options)
      action_items << {klass: klass, options: options}
    end

    def action_items
      @action_items ||= []
    end

    def actions; end

    def get_actions
      @action_items = []
      actions
      action_items
    end

    # Instantiated actions visible in the given view (optionally for a record).
    def actions_for(view: nil, record: nil)
      get_actions.filter_map do |entry|
        action = instantiate_action(entry, view: view, record: record)
        action if action.visible_in_view?(view)
      end
    end

    def find_action_entry(key)
      get_actions.find { |entry| entry[:klass].action_key == key.to_s }
    end

    def instantiate_action(entry, view: nil, record: nil, records: nil)
      records = records || (record ? [record] : [])
      # Expose the acted-on record as `resource.record` inside the action's `fields`
      # (a single-record/show action sees its record; a bulk action sees the
      # first selected record as a representative).
      hydrate(record: records.first) if records.first

      action = entry[:klass].new(
        view: view,
        resource: self,
        user: user,
        arguments: entry.dig(:options, :arguments) || {}
      )
      action.records = records
      action
    end

    # ---- Filters DSL ----

    def filter(klass, **options)
      filter_items << {klass: klass, options: options}
    end

    def filter_items
      @filter_items ||= []
    end

    def filters; end

    def get_filters
      @filter_items = []
      filters
      filter_items.map do |entry|
        entry[:klass].new(arguments: entry.dig(:options, :arguments) || {})
      end
    end

    # ---- Querying ----

    def base_query
      query = model_class.all
      query = query.includes(*self.class.includes) if self.class.includes.present?

      if self.class.index_query
        query = ExecutionContext.new(
          target: self.class.index_query,
          query: query,
          params: params
        ).handle
      end

      query
    end

    def find_record(id, query: nil)
      (query || base_query).find(id)
    end

    def new_record
      model_class.new
    end

    def record_title(target = record)
      return nil if target.nil?

      title_attr = self.class.title

      if title_attr.respond_to?(:call)
        ExecutionContext.new(target: title_attr, record: target, resource: self).handle
      elsif target.respond_to?(title_attr)
        target.public_send(title_attr)
      else
        "#{model_class.model_name.human} ##{target.id}"
      end
    end
  end
end
