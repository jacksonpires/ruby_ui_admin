# frozen_string_literal: true

module RubyUIAdmin
  module Policies
    class PostPolicy < RubyUIAdmin::BasePolicy
      def index? = true

      def show? = true

      def create? = true

      def update? = true

      def destroy? = !!user&.admin?

      def act_on? = true

      # Field-level authorization: only admins can see/edit the views count.
      def view_views_count? = !!user&.admin?

      # Association-level authorization: only admins see the comments association.
      def view_comments? = !!user&.admin?

      # Non-admins only ever see published posts on the index.
      relation_scope do |relation|
        next relation if user&.admin?

        relation.where(published: true)
      end
    end
  end
end
