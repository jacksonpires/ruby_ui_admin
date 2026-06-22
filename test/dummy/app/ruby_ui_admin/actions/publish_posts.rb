# frozen_string_literal: true

module RubyUIAdmin
  module Actions
    class PublishPosts < RubyUIAdmin::BaseAction
      self.name = "Publish"
      self.confirm_button_label = "Publish"
      # Dynamic message proc using the selected records.
      self.message = -> { "Publish #{records.size} selected post(s)?" }

      def handle(query:, fields:, current_user:, **)
        query.each { |post| post.update!(published: true, status: "published") }
        succeed "Published #{query.size} post(s)."
      end
    end
  end
end
