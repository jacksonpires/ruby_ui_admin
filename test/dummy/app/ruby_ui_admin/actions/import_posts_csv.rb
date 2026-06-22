# frozen_string_literal: true

module RubyUIAdmin
  module Actions
    # Exercises a file field in an action: multipart form + uploaded file read via
    # indifferent-access field values (`fields[:csv_file]`), then a bare route helper.
    class ImportPostsCsv < RubyUIAdmin::BaseAction
      self.name = "Import CSV"
      self.standalone = true

      def fields
        field :csv_file, as: :file
      end

      def handle(args)
        file = args[:fields][:csv_file]
        return error("No file provided.") if file.blank?

        titles = file.read.to_s.split("\n").map(&:strip).reject(&:blank?)
        titles.each { |title| Post.create!(title: title) }

        succeed "Imported #{titles.size} post(s) from #{file.original_filename}."
        redirect_to resources_posts_path
      end
    end
  end
end
