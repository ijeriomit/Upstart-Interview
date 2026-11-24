class UserSession < ApplicationRecord
  belongs_to :user, inverse_of: :user_sessions

  # A cookie can restore a session only while its server-side row is active.
  scope :active, -> { where(created_at: 14.days.ago..) }
end
