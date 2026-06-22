# frozen_string_literal: true

module RubyUIAdmin
  module Actions
    # Standalone action (needs no record selection) that exercises the positional
    # `handle(args)` signature and an action form field.
    class ImportPosts < RubyUIAdmin::BaseAction
      self.name = "Import sample"
      self.standalone = true

      def fields
        field :count, as: :number
      end

      def handle(args)
        # Symbol key works thanks to indifferent-access field values.
        count = (args[:fields][:count] || 1).to_i
        count.times { |i| Post.create!(title: "Imported #{i + 1}") }

        succeed "Imported #{count} post(s)."
        # Bare engine route helper resolved inside `handle`.
        redirect_to resources_posts_path
      end
    end
  end
end
