require_relative "../rails_helper"

RSpec.describe AccountPolicy do
  fixtures :users, :accounts

  let(:alex) { users(:alex) }

  describe "#show?" do
    it "allows Alex to view an account he owns" do
      policy = described_class.new(alex, accounts(:checking))

      expect(policy.show?).to be true
    end

    it "denies Alex access to Jordan's account" do
      policy = described_class.new(alex, accounts(:personal))

      expect(policy.show?).to be false
    end
  end

  describe AccountPolicy::Scope do
    it "returns exactly the accounts Alex owns" do
      scope = described_class.new(alex, Account.all)

      expect(scope.resolve.ids).to match_array([accounts(:checking).id, accounts(:savings).id])
    end
  end
end
