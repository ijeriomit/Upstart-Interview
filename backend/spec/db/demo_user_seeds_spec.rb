require_relative "../rails_helper"

RSpec.describe "Demo user seeds" do
  fixtures :users, :accounts, :transactions

  it "sets a missing password in place and preserves it on another seed run" do
    alex = users(:alex)
    checking = accounts(:checking)
    transaction_ids = checking.transactions.ids

    allow(Rails.env).to receive(:development?).and_return(true)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DEMO_ALEX_PASSWORD").and_return("first-test-password")
    allow(ENV).to receive(:[]).with("DEMO_JORDAN_PASSWORD").and_return(nil)

    Rails.application.load_seed

    expect(alex.reload.authenticate("first-test-password")).to eq(alex)
    expect(checking.reload.user_id).to eq(alex.id)
    expect(checking.transactions.ids).to match_array(transaction_ids)

    allow(ENV).to receive(:[]).with("DEMO_ALEX_PASSWORD").and_return("second-test-password")
    expect { Rails.application.load_seed }.not_to change { alex.reload.password_digest }
  end
end
