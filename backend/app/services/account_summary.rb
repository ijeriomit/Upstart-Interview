class AccountSummary
  # Both totals and history use the policy-scoped relation from the controller.
  def self.call(account, transactions)
    # Writers lock this same row before posting. A shared lock keeps the balance,
    # totals, and history from straddling two different commits.
    account.with_lock("FOR SHARE") do
      # PostgreSQL returns an exact sum for each direction that has entries.
      totals = transactions.group(:direction).sum(:amount)
      zero = BigDecimal("0")

      {
        account: AccountJson.call(account),
        totalCredits: UsdAmount.as_json_string(totals.fetch("credit", zero)),
        totalDebits: UsdAmount.as_json_string(totals.fetch("debit", zero)),
        # When timestamps match, higher IDs appear first.
        transactions: transactions.order(created_at: :desc, id: :desc).map do |entry|
          {
            id: entry.id.to_s,
            direction: entry.direction,
            amount: UsdAmount.as_json_string(entry.amount),
            description: entry.description,
            createdAt: entry.created_at.iso8601
          }
        end
      }
    end
  end
end
