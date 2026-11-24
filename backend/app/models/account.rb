class Account < ApplicationRecord
  belongs_to :user, inverse_of: :accounts
  # Preserve transaction history by blocking destroy while entries exist.
  has_many :transactions, inverse_of: :account, dependent: :restrict_with_exception

  # The database also enforces unique names within each user's accounts.
  validates :name, presence: true, uniqueness: { scope: :user_id }
  # A debit that would overdraw the account fails this validation.
  validates :balance, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: UsdAmount::MAX }
end
