class Transaction < ApplicationRecord
  belongs_to :account, inverse_of: :transactions

  validates :direction, inclusion: { in: %w[credit debit] }
  validates :amount, numericality: { greater_than: 0, less_than_or_equal_to: UsdAmount::MAX }
  validates :description, length: { maximum: 120 }
end
