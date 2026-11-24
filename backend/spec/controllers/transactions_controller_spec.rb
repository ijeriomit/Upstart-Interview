require_relative "../rails_helper"

RSpec.describe Api::TransactionsController, type: :controller do
  fixtures :users, :accounts

  let(:account) { accounts(:checking) }

  before do
    allow(controller).to receive(:current_user).and_return(users(:alex))
    # Request specs exercise the CSRF middleware with real cookies and tokens.
    allow(controller).to receive(:protect_against_forgery?).and_return(false)
  end

  it "creates a transaction for the account in the route" do
    expect do
      post_entry(account, direction: "credit", amount: "1.00")
    end.to change { account.transactions.count }.by(1)
  end

  it "renders the updated account summary as JSON" do
    expect(controller).to receive(:render).with(
      json: include(account: include(id: account.id.to_s, balance: "11.10")),
      status: :created
    ).and_call_original

    post_entry(account, direction: "credit", amount: "1.00")

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("account", "balance")).to eq("11.10")
  end

  it "returns not found when the account belongs to another user" do
    expect do
      post_entry(accounts(:personal), direction: "credit", amount: "1.00")
    end.not_to change(Transaction, :count)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
  end

  it "returns forbidden when the transaction policy denies the write" do
    other_account = accounts(:personal)
    # Let the lookup find the account so the real policy can reject the write.
    allow(controller).to receive(:policy_scope).with(Account).and_return(Account.where(id: other_account.id))

    expect do
      post_entry(other_account, direction: "credit", amount: "1.00")
    end.not_to change(Transaction, :count)

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("forbidden")
  end

  it "rejects a transaction with no amount" do
    expect do
      post_entry(account, direction: "credit")
    end.not_to change(Transaction, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_amount")
  end

  it "rejects a transaction with no direction" do
    expect do
      post_entry(account, amount: "1.00")
    end.not_to change(Transaction, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
  end

  it "accepts an empty description" do
    expect do
      post_entry(account, direction: "credit", amount: "1.00", description: "")
    end.to change { account.transactions.where(description: "").count }.by(1)

    expect(response).to have_http_status(:created)
  end

  private

  def post_entry(account, **attributes)
    post :create, params: { account_id: account.id, transaction: attributes }, as: :json
  end
end
