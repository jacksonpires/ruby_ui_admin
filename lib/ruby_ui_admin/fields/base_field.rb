# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Base class for all field types. Fields are pure data/metadata objects; the
    # actual rendering lives in Phlex components (app/components/ruby_ui_admin/fields).
    class BaseField
      attr_reader :id, :options, :block
      attr_accessor :resource

      # Registers the field under a DSL symbol, e.g. `register_as :text`.
      def self.register_as(key)
        @field_type = key.to_sym
        Fields.register(key, self)
      end

      def self.field_type
        @field_type
      end

      def initialize(id, resource: nil, **options, &block)
        @id = id.to_sym
        @resource = resource
        @options = options
        @block = block

        @name = options[:name]
        @required = options.fetch(:required, false)
        @readonly = options.fetch(:readonly, false)
        @sortable = options.fetch(:sortable, false)
        @filterable = options.fetch(:filterable, false)
        @link_to_record = options.fetch(:link_to_record, false)
        @format_using = options[:format_using]
        @help = options[:help]
        @description = options[:description]
        @visible = options[:visible]
        @placeholder = options[:placeholder]
        @default = options[:default]
        @only_on = normalize_views(options[:only_on])
        @hide_on = normalize_views(options[:hide_on])
      end

      def type
        self.class.field_type
      end

      def name
        return @name if @name

        model = resource&.model_class
        # Uses the model's i18n attribute name (activerecord.attributes.*),
        # falling back to a humanized id.
        model.respond_to?(:human_attribute_name) ? model.human_attribute_name(id) : id.to_s.humanize
      end

      def help = @help
      def description = @description
      def placeholder = @placeholder
      def required? = !!@required
      def readonly? = !!@readonly
      def sortable? = !!@sortable
      def filterable? = !!@filterable
      def link_to_record? = !!@link_to_record

      # The underlying attribute name on the model (overridable by subclasses,
      # e.g. belongs_to appends `_id`).
      def database_id
        id
      end

      # Raw value read from the record (or computed via a block). When a `view_context`
      # is given, the computed block can use view/url helpers (`link_to`, `main_app`, …).
      def value(record, view_context: nil)
        return nil if record.nil?

        if block
          ExecutionContext.new(
            target: block,
            record: record,
            resource: resource,
            current_user: resource&.user,
            view_context: view_context
          ).handle
        elsif record.respond_to?(id)
          record.public_send(id)
        end
      end

      # Value formatted for display.
      def formatted_value(record, view_context: nil)
        raw = value(record, view_context: view_context)
        return raw if @format_using.nil?

        ExecutionContext.new(
          target: @format_using,
          value: raw,
          record: record,
          resource: resource,
          current_user: resource&.user,
          view_context: view_context
        ).handle
      end

      # Assigns a submitted value back onto the record.
      def fill_value(record, value)
        setter = "#{database_id}="
        record.public_send(setter, value) if record.respond_to?(setter)
      end

      # Which form param this field reads/writes.
      def permitted_param
        database_id
      end

      # The strong-parameters fragment for this field (scalar by default; fields with
      # hash/array values override, e.g. boolean_group -> { name => {} }, files -> { name => [] }).
      def permit_param
        permitted_param
      end

      # All strong-params fragments this field contributes. Defaults to a single `permit_param`;
      # fields that read extra inputs (e.g. a file field's remove checkbox) return more.
      def permit_params
        [permit_param]
      end

      # Applies the submitted (permitted) `attributes` to the record for this field. Default just
      # assigns `permitted_param`; fields with extra inputs override (e.g. file remove).
      def fill(record, attributes)
        key = permitted_param.to_s
        fill_value(record, attributes[key]) if attributes.key?(key)
      end

      def has_default?
        !@default.nil?
      end

      # The field's default for a new record (literal or a proc evaluated with
      # `record`, `resource` and `current_user` available).
      def default_value(record = nil)
        return @default unless @default.respond_to?(:call)

        ExecutionContext.new(
          target: @default,
          record: record,
          resource: resource,
          current_user: resource&.user
        ).handle
      end

      # Conditional visibility (`visible: -> { current_user.admin? }`), evaluated with
      # `view`/`record`/`resource`/`current_user`. A literal is used as-is. Defaults to visible.
      def visible?(view: nil, record: nil)
        return true if @visible.nil?

        result =
          if @visible.respond_to?(:call)
            ExecutionContext.new(
              target: @visible,
              view: View.wrap(view),
              record: record,
              resource: resource,
              current_user: resource&.user
            ).handle
          else
            @visible
          end

        !!result
      end

      def visible_in_view?(view)
        view = view.to_sym
        return @only_on.include?(view) if @only_on
        return !@hide_on.include?(view) if @hide_on

        !default_hidden_views.include?(view)
      end

      # Views where a field type is hidden unless `only_on`/`hide_on` say otherwise.
      # Overridden by heavy/association fields (e.g. has_many hides everywhere but show).
      def default_hidden_views
        []
      end

      # Whether the field can be sorted, and the column/expression to sort by.
      # `sortable: true` sorts by the database column; `sortable: ->{...}` is custom.
      def sort_lambda
        @sortable.respond_to?(:call) ? @sortable : nil
      end

      private

      def normalize_views(value)
        return nil if value.nil?

        # `:forms` = new+edit; `:display` = index+show (view groups).
        Array(value).flat_map do |v|
          case v.to_sym
          when :forms then %i[new edit]
          when :display then %i[index show]
          else v.to_sym
          end
        end
      end
    end
  end
end
