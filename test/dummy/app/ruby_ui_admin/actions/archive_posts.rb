# frozen_string_literal: true

module RubyUIAdmin
  module Actions
    # Sets no message in `handle` — exercises the default "ran successfully" confirmation.
    class ArchivePosts < RubyUIAdmin::BaseAction
      self.name = "Archive"

      def handle(query:, **)
        query.each { |post| post.update!(status: "archived") }
      end
    end
  end
end
