# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :post, optional: true

  validates :body, presence: true

  def to_label
    body.to_s.truncate(40)
  end
end
