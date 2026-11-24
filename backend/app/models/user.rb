class User < ApplicationRecord
  # inverse_of links user.accounts and account.user in memory. Destroying a
  # user raises while they still own accounts.
  has_many :accounts, inverse_of: :user, dependent: :restrict_with_exception

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # Interview-only credentials are plain text; the session row, not this field,
  # decides whether a browser remains signed in after a request.
  validates :password, presence: true, on: :create
  validates :password, length: { maximum: 128 }, allow_nil: true
end
