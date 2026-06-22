# frozen_string_literal: true

class CreateDummySchema < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email, null: false
      t.boolean :admin, default: false, null: false
      t.timestamps
    end

    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.boolean :published, default: false, null: false
      t.integer :views_count, default: 0
      t.references :user, foreign_key: true
      t.timestamps
    end

    create_table :comments do |t|
      t.text :body, null: false
      t.references :post, foreign_key: true
      t.timestamps
    end
  end
end
