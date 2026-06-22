# frozen_string_literal: true

class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_and_belongs_to_many :tags
  has_one_attached :avatar
  has_many_attached :documents

  validates :email, presence: true

  def to_label
    name.presence || email
  end

  def admin?
    !!admin
  end
end
