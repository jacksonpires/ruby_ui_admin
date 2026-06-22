# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Single ActiveStorage attachment.
    class FileField < BaseField
      register_as :file

      def default_hidden_views
        %i[index]
      end

      def multiple?
        false
      end

      def accept
        options[:accept]
      end

      # Max display size (W×H, px) for an image thumbnail on the show view. Accepts an Integer
      # (square, e.g. `preview_size: 100`) or `[width, height]` (e.g. `[120, 80]`). Applied as a
      # max-width/max-height (the image scales down to fit, preserving aspect). Defaults to 64×64.
      def preview_size
        options[:preview_size]
      end

      def attachment(record)
        record.public_send(id) if record.respond_to?(id)
      end

      def attached?(record)
        att = attachment(record)
        att.respond_to?(:attached?) && att.attached?
      end

      # Skip empty uploads so we don't blow away an existing attachment.
      def fill_value(record, value)
        return if value.blank?

        setter = "#{id}="
        record.public_send(setter, value) if record.respond_to?(setter)
      end

      # Form param for the "remove current file" checkbox.
      def remove_param
        :"#{permitted_param}_remove"
      end

      # Also permit the remove checkbox alongside the upload.
      def permit_params
        [permit_param, remove_param]
      end

      # Purge the current attachment when "remove" is checked; otherwise assign the upload
      # (skipping blank so an empty input doesn't wipe an existing attachment).
      def fill(record, attributes)
        if ActiveModel::Type::Boolean.new.cast(attributes[remove_param.to_s])
          record.public_send(id).purge if attached?(record)
          return
        end

        super
      end
    end
  end
end
