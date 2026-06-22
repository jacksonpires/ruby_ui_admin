# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    class PostsCount < RubyUIAdmin::Cards::MetricCard
      self.label = "Total posts"

      def query
        Post.count
      end
    end
  end
end
