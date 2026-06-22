# frozen_string_literal: true

class AddUserDemoFields < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :role, :string
    add_column :users, :state, :string, default: "active", null: false
    add_column :users, :secret, :string
    add_column :users, :token, :string
    add_column :users, :bio, :text
    add_column :users, :birthday, :date
  end
end
