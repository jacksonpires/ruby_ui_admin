# frozen_string_literal: true

require "test_helper"

module RubyUIAdmin
  class ScopeTest < ActiveSupport::TestCase
    test "scope_key strips the namespace and underscores" do
      assert_equal "published_posts", Scopes::PublishedPosts.scope_key
      assert_equal "draft_posts", Scopes::DraftPosts.scope_key
    end

    test "apply runs the scope lambda against the query" do
      Post.create!(title: "Pub", published: true)
      Post.create!(title: "Draft", published: false)

      scoped = Scopes::PublishedPosts.new.apply(Post.all)

      assert_equal ["Pub"], scoped.pluck(:title)
    end

    test "scopes are not default unless declared" do
      refute Scopes::PublishedPosts.new.default?
    end

    test "resource collects its scopes" do
      resource = Resources::Post.new
      keys = resource.get_scopes.map(&:key)

      assert_equal %w[published_posts draft_posts], keys
      assert_nil resource.default_scope_entry
      assert_equal Scopes::DraftPosts, resource.find_scope("draft_posts").class
    end

    test "default_scope_entry returns the scope flagged as default" do
      klass = Class.new(RubyUIAdmin::BaseResource) do
        self.model_class = Post
        def scopes
          scope RubyUIAdmin::Scopes::PublishedPosts
        end
      end

      RubyUIAdmin::Scopes::PublishedPosts.default = true
      assert_equal "published_posts", klass.new.default_scope_entry&.key
    ensure
      RubyUIAdmin::Scopes::PublishedPosts.default = false
    end

    test "a Symbol scope calls the model's named scope" do
      Post.create!(title: "Pub", published: true)
      Post.create!(title: "Draft", published: false)

      scoped = Scopes::PublishedViaSymbol.new.apply(Post.all)

      assert_equal ["Pub"], scoped.pluck(:title)
    end

    test "default: true at attachment overrides the class default" do
      klass = Class.new(RubyUIAdmin::BaseResource) do
        self.model_class = Post
        def scopes
          scope RubyUIAdmin::Scopes::PublishedPosts, default: true
          scope RubyUIAdmin::Scopes::DraftPosts
        end
      end

      resource = klass.new
      assert_equal "published_posts", resource.default_scope_entry&.key
      assert resource.find_scope("published_posts").default?
      refute resource.find_scope("draft_posts").default?
    end
  end
end
