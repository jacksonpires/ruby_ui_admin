# frozen_string_literal: true

class AddPostPublishedOn < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :published_on, :date
  end
end
