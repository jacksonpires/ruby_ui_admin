# frozen_string_literal: true

module RubyUIAdmin
  module Cards
    # Partial card: renders arbitrary HTML returned by `query`.
    class WelcomePanel < RubyUIAdmin::Cards::PartialCard
      self.label = "Welcome"

      def query
        <<~HTML
          <p class="text-sm text-muted-foreground">
            This is a <strong>partial card</strong> rendering raw HTML.
            There are #{Post.count} posts and #{User.count} users.
          </p>
        HTML
      end
    end
  end
end
