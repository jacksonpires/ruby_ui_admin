# frozen_string_literal: true

module RubyUIAdmin
  module Fields
    # Multiple ActiveStorage attachments (has_many_attached).
    class FilesField < FileField
      register_as :files

      def multiple?
        true
      end

      # Submitted as an array (record[avatars][]).
      def permit_param
        {permitted_param => []}
      end

      # Form param holding the ids of attachments marked for removal.
      def remove_ids_param
        :"#{permitted_param}_remove_ids"
      end

      # Permit the upload array plus the array of attachment ids to remove.
      def permit_params
        [permit_param, {remove_ids_param => []}]
      end

      def attachments(record)
        att = attachment(record)
        return [] unless att.respond_to?(:attached?) && att.attached?

        att
      end

      # Purge the attachments the user checked, then APPEND any new uploads (unlike the single
      # `:file`, new files don't replace the existing set). Both skip blanks/empties.
      def fill(record, attributes)
        purge_marked(record, attributes[remove_ids_param.to_s])
        attach_new(record, attributes[permitted_param.to_s])
      end

      private

      def purge_marked(record, ids)
        ids = Array(ids).map(&:to_s).reject(&:blank?)
        return if ids.empty?

        collection = record.public_send(id)
        return unless collection.respond_to?(:each)

        collection.each { |att| att.purge if ids.include?(att.id.to_s) }
      end

      def attach_new(record, files)
        files = Array(files).reject(&:blank?)
        return if files.empty?

        record.public_send(id).attach(files)
      end
    end
  end
end
