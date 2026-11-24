require_relative "../rails_helper"

RSpec.describe "Accounts API", type: :request do
  fixtures :users, :accounts, :transactions

  around do |example|
    previous_demo_user = ENV["DEMO_USER_EMAIL"]
    example.run
  ensure
    ENV["DEMO_USER_EMAIL"] = previous_demo_user
  end

  before do
    ENV["DEMO_USER_EMAIL"] = users(:alex).email
  end

  it "shows the configured user and ignores client-supplied identity" do
    get "/api/me", headers: { "X-User-ID" => users(:jordan).id.to_s }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("user", "id")).to eq(users(:alex).id.to_s)
  end

  it "requires a configured demo user" do
    ENV["DEMO_USER_EMAIL"] = "absent@example.test"
    get api_accounts_path

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
  end

  it "lists only the current user's accounts and scopes their transactions" do
    get api_accounts_path

    expect(response).to have_http_status(:ok)
    account_ids = response.parsed_body.fetch("accounts").pluck("id")
    expect(account_ids).to eq([accounts(:checking).id.to_s, accounts(:savings).id.to_s])

    visible_transactions = Pundit.policy_scope!(users(:alex), Transaction)
    expect(visible_transactions.ids).to match_array([transactions(:deposit).id, transactions(:payment).id])
  end

  it "shows exact totals and newest transactions first" do
    get api_account_path(accounts(:checking))

    expect(response).to have_http_status(:ok)
    summary = response.parsed_body
    expect(summary.dig("account", "balance")).to eq("10.10")
    expect(summary.fetch("totalCredits")).to eq("12.35")
    expect(summary.fetch("totalDebits")).to eq("2.25")
    expect(summary.fetch("transactions").pluck("id")).to eq([transactions(:payment).id.to_s, transactions(:deposit).id.to_s])
  end

  it "posts credits and debits and updates the balance exactly" do
    account = accounts(:checking)

    expect do
      post_entry(account, direction: "credit", amount: "0.20")
      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("account", "balance")).to eq("10.30")

      post_entry(account, direction: "debit", amount: "0.10")
      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("account", "balance")).to eq("10.20")
    end.to change(Transaction, :count).by(2)

    expect(account.reload.balance).to eq(BigDecimal("10.20"))
  end

  it "rejects JSON numbers, excessive scale, and invalid directions without writing" do
    account = accounts(:checking)

    expect do
      [0.20, "0.201"].each do |amount|
        post_entry(account, direction: "credit", amount: amount)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body.dig("error", "code")).to eq("invalid_amount")
      end

      post_entry(account, direction: "transfer", amount: "0.20")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end.not_to change(Transaction, :count)

    expect(account.reload.balance).to eq(BigDecimal("10.10"))
  end

  it "rolls back the transaction row when the balance update is invalid" do
    account = accounts(:checking)

    expect do
      post_entry(account, direction: "debit", amount: "10.11")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end.not_to change(Transaction, :count)

    expect(account.reload.balance).to eq(BigDecimal("10.10"))
  end

  it "cannot read or write another user's account" do
    other_account = accounts(:personal)
    get api_account_path(other_account)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")

    expect do
      post_entry(other_account, direction: "credit", amount: "1.00")
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "code")).to eq("not_found")
    end.not_to change(Transaction, :count)

    expect(other_account.reload.balance).to eq(BigDecimal("50.00"))
  end

  it "requires a transaction object" do
    post api_account_transactions_path(accounts(:checking)), params: { amount: "1.00" }, as: :json

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig("error", "code")).to eq("bad_request")
  end

  private

  def post_entry(account, **attributes)
    post api_account_transactions_path(account), params: { transaction: attributes }, as: :json
  end
end
