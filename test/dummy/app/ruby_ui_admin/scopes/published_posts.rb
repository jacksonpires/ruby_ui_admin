# frozen_string_literal: true

module RubyUIAdmin
  module Scopes
    class PublishedPosts < RubyUIAdmin::Scopes::BaseScope
      self.name = "Published"
      self.description = "Only published posts"
      self.scope = -> { query.where(published: true) }
    end
  end
end
