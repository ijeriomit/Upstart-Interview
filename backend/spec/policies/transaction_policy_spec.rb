require_relative "../rails_helper"

RSpec.describe TransactionPolicy do
  fixtures :users, :accounts, :transactions

  let(:alex) { users(:alex) }

  describe "#create?" do
    it "allows Alex to post a transaction to an account he owns" do
      transaction = Transaction.new(account: accounts(:checking))
      policy = described_class.new(alex, transaction)

      expect(policy.create?).to be true
    end

    it "denies Alex permission to post a transaction to Jordan's account" do
      transaction = Transaction.new(account: accounts(:personal))
      policy = described_class.new(alex, transaction)

      expect(policy.create?).to be false
    end
  end

  describe TransactionPolicy::Scope do
    it "returns exactly the transactions from accounts Alex owns" do
      scope = described_class.new(alex, Transaction.all)

      expect(scope.resolve.ids).to match_array([transactions(:deposit).id, transactions(:payment).id])
    end
  end
end
