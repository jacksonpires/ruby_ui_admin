# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :user, optional: true
  has_many :comments, dependent: :destroy

  validates :title, presence: true

  scope :published, -> { where(published: true) }

  def to_label
    title
  end
end
