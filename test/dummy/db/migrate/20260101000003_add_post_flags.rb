# frozen_string_literal: true

class AddPostFlags < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :flags, :json
  end
end
