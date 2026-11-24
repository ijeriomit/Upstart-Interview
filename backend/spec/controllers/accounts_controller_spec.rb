require_relative "../rails_helper"

RSpec.describe Api::AccountsController, "controller actions", type: :controller do
  fixtures :users, :accounts

  before do
    allow(controller).to receive(:current_user).and_return(users(:alex))
  end

  it "orders the scoped accounts by name and ID" do
    # Account names are unique per user, so check the tie-breaker on the query.
    expect(controller).to receive(:policy_scope).with(Account).and_wrap_original do |policy_scope, model|
      scoped_accounts = policy_scope.call(model)
      expect(scoped_accounts).to receive(:order).with(:name, :id).and_call_original
      scoped_accounts
    end

    get :index
  end

  it "serializes each scoped account once" do
    expect(AccountJson).to receive(:call).with(accounts(:savings)).and_call_original
    expect(AccountJson).to receive(:call).with(accounts(:checking)).and_call_original

    get :index
  end

  it "renders the ordered account list as JSON" do
    checking = accounts(:checking)
    savings = accounts(:savings)
    savings.update!(name: "Car savings")
    expected_accounts = [
      { id: savings.id.to_s, name: "Car savings", balance: "0.00" },
      { id: checking.id.to_s, name: "Everyday checking", balance: "10.10" }
    ]
    expect(controller).to receive(:render).with(json: { accounts: expected_accounts }).and_call_original

    get :index

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("accounts" => expected_accounts.map(&:stringify_keys))
  end
end

RSpec.describe Api::AccountsController, "HTTP requests", type: :request do
  fixtures :users, :accounts, :transactions

  before do
    alex = users(:alex)
    password = "test-sign-in-password"
    alex.update!(password: password)
    @auth_headers = { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(alex.email, password) }
  end

  it "requires a signed-in user" do
    anonymous = open_session
    anonymous.get api_accounts_path

    expect(anonymous.response).to have_http_status(:unauthorized)
    expect(anonymous.response.parsed_body.dig("error", "code")).to eq("unauthorized")
  end

  it "lists only the current user's accounts and scopes their transactions" do
    get api_accounts_path, headers: @auth_headers

    expect(response).to have_http_status(:ok)
    account_ids = response.parsed_body.fetch("accounts").pluck("id")
    expect(account_ids).to eq([accounts(:checking).id.to_s, accounts(:savings).id.to_s])

    visible_transactions = Pundit.policy_scope!(users(:alex), Transaction)
    expect(visible_transactions.ids).to match_array([transactions(:deposit).id, transactions(:payment).id])
  end

  it "shows exact totals and newest transactions first" do
    get api_account_path(accounts(:checking)), headers: @auth_headers

    expect(response).to have_http_status(:ok)
    summary = response.parsed_body
    expect(summary.dig("account", "balance")).to eq("10.10")
    expect(summary.fetch("totalCredits")).to eq("12.35")
    expect(summary.fetch("totalDebits")).to eq("2.25")
    expect(summary.fetch("transactions").pluck("id")).to eq([transactions(:payment).id.to_s, transactions(:deposit).id.to_s])
  end

  it "cannot read another user's account" do
    other_account = accounts(:personal)
    get api_account_path(other_account), headers: @auth_headers

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
  end

end
