class Account < ApplicationRecord
  belongs_to :user, inverse_of: :accounts
  has_many :transactions, inverse_of: :account, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :balance, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: UsdAmount::MAX }
end
