# frozen_string_literal: true

module RubyUIAdmin
  module Scopes
    # Uses the model's named scope (`Post.published`) via a Symbol instead of a lambda.
    class PublishedViaSymbol < RubyUIAdmin::Scopes::BaseScope
      self.name = "Published (symbol)"
      self.scope = :published
    end
  end
end
