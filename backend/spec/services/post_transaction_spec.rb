require_relative "../rails_helper"

RSpec.describe PostTransaction do
  fixtures :all

  # Worker connections need to see a committed account.
  self.use_transactional_tests = false

  it "applies concurrent credits to the latest locked balance" do
    workers = []
    account = users(:alex).accounts.create!(name: "Concurrent account")
    copies = [Account.find(account.id), Account.find(account.id)]

    copies.zip(%w[0.10 0.20]).each do |copy, amount|
      workers << Thread.new do
        Account.connection_pool.with_connection do
          described_class.call(copy, { direction: "credit", amount: amount })
        end
      end
    end
    workers.each(&:value)

    expect(account.reload.balance).to eq(BigDecimal("0.30"))
    expect(account.transactions.count).to eq(2)
  ensure
    workers.each do |worker|
      worker.join
    rescue StandardError
      # Thread#value already reports worker failures to RSpec.
    end
    if account
      Transaction.where(account_id: account.id).delete_all
      account.destroy!
    end
  end
end
