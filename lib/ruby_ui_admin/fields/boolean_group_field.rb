# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # A group of checkboxes whose value is a Hash of `{ key => boolean }`.
    #   field :feature_flags, as: :boolean_group, options: { "beta" => "Beta", "pro" => "Pro" }
    class BooleanGroupField < BaseField
      register_as :boolean_group

      def default_hidden_views
        %i[index]
      end

      # `{ key => label }`. `options:` may be a Hash, an Array of keys, or a lambda.
      def group_options
        raw = options[:options] || {}
        raw = ExecutionContext.new(target: raw, resource: resource).handle if raw.respond_to?(:call)

        raw.is_a?(Hash) ? raw.transform_keys(&:to_s) : Array(raw).to_h { |key| [key.to_s, key.to_s.humanize] }
      end

      def checked?(record, key)
        value = value(record)
        return false unless value.respond_to?(:[])

        truthy?(value[key.to_s].nil? ? value[key.to_sym] : value[key.to_s])
      end

      def enabled_labels(record)
        group_options.select { |key, _label| checked?(record, key) }.values
      end

      # Hash param: permit arbitrary nested keys.
      def permit_param
        {permitted_param => {}}
      end

      # Build the full { key => bool } hash from the submitted (checked-only) params.
      def fill_value(record, submitted)
        submitted ||= {}
        result = group_options.keys.to_h { |key| [key, truthy?(submitted[key])] }

        setter = "#{database_id}="
        record.public_send(setter, result) if record.respond_to?(setter)
      end

      private

      def truthy?(value)
        ["1", "true", true].include?(value)
      end
    end
  end
end
