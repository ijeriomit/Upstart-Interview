require_relative "../rails_helper"

RSpec.describe Api::AccountsController, type: :controller do
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
