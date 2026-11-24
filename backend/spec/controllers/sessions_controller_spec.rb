require_relative "../rails_helper"

RSpec.describe Api::SessionsController, "HTTP requests", type: :request do
  fixtures :users, :accounts, :transactions

  let(:alex) { users(:alex) }
  let(:jordan) { users(:jordan) }
  let(:password) { "test-sign-in-password" }

  before do
    alex.update!(password: password)
    jordan.update!(password: password)
  end

  it "signs in with the stored mock password" do
    post "/api/session", params: { session: { email: alex.email, password: password } }, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("user")).to eq(
      "id" => alex.id.to_s, "name" => alex.name, "email" => alex.email
    )
    expect(response.body).not_to include(password)
  end

  it "returns the same unauthorized response for a bad password and unknown email" do
    post "/api/session", params: { session: { email: alex.email, password: "wrong" } }, as: :json
    wrong_password = response.parsed_body

    post "/api/session", params: { session: { email: "missing@example.test", password: password } }, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to eq(wrong_password)
  end

  it "requires credentials for protected account reads and writes" do
    get api_accounts_path
    expect(response).to have_http_status(:unauthorized)

    expect do
      post api_account_transactions_path(accounts(:checking)),
        params: { transaction: { amount: "1.00", direction: "credit" } }, as: :json
    end.not_to change(Transaction, :count)
    expect(response).to have_http_status(:unauthorized)
  end

  it "uses the Basic credential on each request, regardless of an identity header" do
    headers = {
      "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(alex.email, password),
      "X-User-ID" => jordan.id.to_s
    }
    get "/api/me", headers: headers
    expect(response.parsed_body.dig("user", "id")).to eq(alex.id.to_s)

    get api_account_path(accounts(:personal)), headers: headers
    expect(response).to have_http_status(:not_found)
  end

end
