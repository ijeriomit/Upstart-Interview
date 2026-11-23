require "test_helper"

class PostTransactionTest < ActiveSupport::TestCase
  # Worker connections can only see committed rows, so this case creates and
  # cleans up its own account outside Rails' test transaction.
  self.use_transactional_tests = false

  test "concurrent credits read the latest locked balance" do
    account = users(:alex).accounts.create!(name: "Concurrent account")
    # Each request starts with a separate, stale copy of the same balance.
    copies = [Account.find(account.id), Account.find(account.id)]

    workers = copies.zip(%w[0.10 0.20]).map do |copy, amount|
      Thread.new do
        Account.connection_pool.with_connection do
          PostTransaction.call(copy, { direction: "credit", amount: amount })
        end
      end
    end
    workers.each(&:value)

    assert_equal BigDecimal("0.30"), account.reload.balance
    assert_equal 2, account.transactions.count
  ensure
    workers&.each(&:join)
    if account
      Transaction.where(account_id: account.id).delete_all
      account.destroy!
    end
  end
end
