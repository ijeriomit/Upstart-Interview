require_relative "../rails_helper"

RSpec.describe "Sessions API", type: :request do
  fixtures :users, :accounts, :transactions

  let(:alex) { users(:alex) }
  let(:jordan) { users(:jordan) }
  let(:password) { "test-sign-in-password" }
  let(:cookie_name) { Rails.application.config.session_options.fetch(:key) }

  before do
    alex.update!(password: password)
    jordan.update!(password: password)
  end

  it "restores the signed-in user's identity and account access on later requests" do
    sign_in(alex, csrf_token)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("user")).to eq("id" => alex.id.to_s, "name" => alex.name, "email" => alex.email)

    get "/api/me", headers: { "X-User-ID" => jordan.id.to_s }
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.parsed_body.dig("user", "id")).to eq(alex.id.to_s)

    get api_account_path(accounts(:checking))
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("account", "id")).to eq(accounts(:checking).id.to_s)

    get api_account_path(accounts(:personal))
    expect(response).to have_http_status(:not_found)
  end

  it "responds identically to a wrong password and an unknown email" do
    token = csrf_token

    expect do
      sign_in(alex, token, password: "wrong-password")
      expect(response).to have_http_status(:unauthorized)
      wrong_password_response = response.parsed_body

      post "/api/session", params: { session: { email: "absent@example.test", password: password } },
        headers: { "X-CSRF-Token" => token }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(wrong_password_response)
      expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
    end.not_to change(UserSession, :count)
  end

  it "returns unauthorized for anonymous protected writes" do
    post api_account_transactions_path(accounts(:checking)),
      params: { transaction: { amount: "1.00", direction: "credit" } }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
  end

  it "rejects sign-in without a CSRF token" do
    expect do
      post "/api/session", params: { session: { email: alex.email, password: password } }, as: :json
    end.not_to change(UserSession, :count)

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_csrf_token")
  end

  it "rejects a cross-origin sign-in even with a valid CSRF token" do
    token = csrf_token

    expect do
      post "/api/session", params: { session: { email: alex.email, password: password } },
        headers: { "X-CSRF-Token" => token, "Origin" => "https://other.example.test" }, as: :json
    end.not_to change(UserSession, :count)

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_csrf_token")
  end

  it "rejects protected writes without a CSRF token" do
    sign_in(alex, csrf_token)

    expect do
      post api_account_transactions_path(accounts(:checking)),
        params: { transaction: { amount: "1.00", direction: "credit" } }, as: :json
    end.not_to change(Transaction, :count)

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_csrf_token")
  end

  it "rotates the CSRF token on login and revokes the cookie on logout" do
    original_token = csrf_token
    sign_in(alex, original_token)
    replay = client_with_current_cookie

    delete "/api/session", headers: { "X-CSRF-Token" => original_token }
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_csrf_token")

    expect do
      delete "/api/session", headers: { "X-CSRF-Token" => csrf_token }
    end.to change(UserSession, :count).by(-1)
    expect(response).to have_http_status(:no_content)
    expect(response.body).to be_empty
    expect(cookies[cookie_name]).to be_blank

    get "/api/me"
    expect(response).to have_http_status(:unauthorized)

    replay.get "/api/me"
    expect(replay.response).to have_http_status(:unauthorized)
  end

  it "revokes the previous cookie when the browser signs in as another user" do
    sign_in(alex, csrf_token)
    replay = client_with_current_cookie

    expect do
      sign_in(jordan, csrf_token)
    end.not_to change(UserSession, :count)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("user", "id")).to eq(jordan.id.to_s)

    get api_accounts_path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("accounts").pluck("id")).to eq([accounts(:personal).id.to_s])

    replay.get "/api/me"
    expect(replay.response).to have_http_status(:unauthorized)
  end

  private

  def csrf_token
    get "/api/csrf"
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("no-store")
    response.parsed_body.fetch("csrfToken")
  end

  def sign_in(user, token, password: self.password)
    post "/api/session", params: { session: { email: user.email, password: password } },
      headers: { "X-CSRF-Token" => token }, as: :json
  end

  def client_with_current_cookie
    replay = open_session
    replay.cookies[cookie_name] = cookies[cookie_name]
    replay.get "/api/me"
    expect(replay.response).to have_http_status(:ok)
    replay
  end
end
