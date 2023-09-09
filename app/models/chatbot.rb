# frozen_string_literal: true

class Chatbot < ApplicationRecord
  enum category: %i[assistant]

  belongs_to :user, optional: true, class_name: 'User', foreign_key: 'user_id'

  def increment_access_count!
    increment(:access_count).save
  end

  def has_expired?
    expires_at.present? && Time.current > expires_at
  end
end
