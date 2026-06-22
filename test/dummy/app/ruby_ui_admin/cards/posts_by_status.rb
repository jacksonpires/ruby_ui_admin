# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    class PostsByStatus < RubyUIAdmin::Cards::ChartCard
      self.label = "Posts by status"

      def query
        Post.group(:status).count
      end
    end
  end
end
