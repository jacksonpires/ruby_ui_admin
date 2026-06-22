# frozen_string_literal: true

class CreateProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :profiles do |t|
      t.references :user, foreign_key: true
      t.string :headline
      t.text :bio
      t.timestamps
    end
  end
end
