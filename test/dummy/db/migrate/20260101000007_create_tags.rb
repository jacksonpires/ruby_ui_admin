# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.timestamps
    end

    # habtm join table for User <-> Tag (Rails convention: alphabetical "tags_users").
    create_table :tags_users, id: false do |t|
      t.references :tag, foreign_key: true
      t.references :user, foreign_key: true
    end
  end
end
