# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    # Metric card demonstrating prefix/suffix (passed when attached on the dashboard).
    class AverageViews < RubyUIAdmin::Cards::MetricCard
      self.label = "Average views"

      def query
        Post.average(:views_count).to_f.round(1)
      end
    end
  end
end
