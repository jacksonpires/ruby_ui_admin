# frozen_string_literal: true

# Per-resource controller demonstrating lifecycle-hook overrides.
module RubyUIAdmin
  class CommentsController < RubyUIAdmin::ResourcesController
    def create_success_action
      redirect_to resources_index_path, notice: "Custom comment created!"
    end

    def after_update_path
      resources_index_path
    end
  end
end
