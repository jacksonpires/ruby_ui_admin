# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user, optional: true

  def to_label = headline.presence || "Profile ##{id}"
end
