# frozen_string_literal: true

module RubyUIAdmin
  module Scopes
    class DraftPosts < RubyUIAdmin::Scopes::BaseScope
      self.name = "Drafts"
      self.scope = -> { query.where(status: "draft") }
    end
  end
end
