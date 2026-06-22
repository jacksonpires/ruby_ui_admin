# frozen_string_literal: true

class AddPostExtras < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :status, :string, default: "draft", null: false
    add_column :posts, :homepage, :string
    add_column :posts, :metadata, :json
  end
end
