# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Renders the value as a colored badge. Map values to variants with
    # `options: { active: :success, pending: :warning, ... }`.
    class BadgeField < BaseField
      register_as :badge

      DEFAULT_VARIANT = :gray

      def variant_for(record)
        mapping = options[:options] || {}
        key = value(record)
        (mapping[key] || mapping[key.to_s] || mapping[key.to_s.to_sym] || DEFAULT_VARIANT).to_sym
      end
    end
  end
end
