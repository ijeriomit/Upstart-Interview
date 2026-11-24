class Transaction < ApplicationRecord
  belongs_to :account, inverse_of: :transactions

  # Keep the amount positive. The direction tells PostTransaction which
  # operation to apply to the account balance.
  validates :direction, inclusion: { in: %w[credit debit] }
  validates :amount, numericality: { greater_than: 0, less_than_or_equal_to: UsdAmount::MAX }
  validates :description, length: { maximum: 120 }
end
