require_relative "../rails_helper"

RSpec.describe Api::UsersController, "controller actions", type: :controller do
  fixtures :users

  let(:alex) { users(:alex) }
  let(:jordan) { users(:jordan) }
  let(:expected_identity) { { "id" => alex.id.to_s, "email" => alex.email } }

  before do
    allow(controller).to receive(:current_user).and_return(alex)
  end

  it "returns the current user when both parameters match" do
    get :show, params: { id: alex.id, email: alex.email }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("user")).to include(expected_identity)
  end

  it "returns the current user when the ID matches and the email differs" do
    get :show, params: { id: alex.id, email: jordan.email }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("user")).to include(expected_identity)
  end

  it "rejects a mismatched ID even when the email matches" do
    get :show, params: { id: jordan.id, email: alex.email }

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("forbidden")
  end

  it "returns the current user when only a matching email is supplied" do
    get :show, params: { email: alex.email }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("user")).to include(expected_identity)
  end

  it "rejects a mismatched email when no ID is supplied" do
    get :show, params: { email: jordan.email }

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig("error", "code")).to eq("forbidden")
  end
end

RSpec.describe Api::UsersController, "HTTP requests", type: :request do
  fixtures :users, :accounts, :transactions

  let(:user) { { name: "Taylor Morgan", email: "TAYLOR@example.test", password: "demo-password" } }
  let(:accounts) do
    [
      { name: "Daily", accountType: "checking", initialDeposit: "0" },
      { name: "Rainy day", accountType: "savings", initialDeposit: "25.10" }
    ]
  end

  it "shows the signed-in user and ignores client-supplied identity headers" do
    alex = users(:alex)
    alex.update!(password: "test-sign-in-password")
    get "/api/me", headers: {
      "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(alex.email, alex.password),
      "X-User-ID" => users(:jordan).id.to_s
    }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("user", "id")).to eq(alex.id.to_s)
  end

  it "creates a user, typed accounts, and only positive opening deposits" do
    expect { register(user: user, accounts: accounts) }
      .to change(User, :count).by(1)
      .and change(Account, :count).by(2)
      .and change(Transaction, :count).by(1)

    expect(response).to have_http_status(:created)
    created = User.find_by!(email: "taylor@example.test")
    expect(response.parsed_body.fetch("user")).to eq(
      "id" => created.id.to_s, "name" => user[:name], "email" => created.email
    )
    expect(response.body).not_to include(user[:password])
    expect(created.accounts.order(:name).pluck(:name, :account_type, :balance)).to eq([
      ["Daily", "checking", BigDecimal("0.00")],
      ["Rainy day", "savings", BigDecimal("25.10")]
    ])
    expect(created.accounts.find_by!(name: "Daily").transactions).to be_empty
    expect(created.accounts.find_by!(name: "Rainy day").transactions.first.description).to eq("Opening deposit")
  end

  it "rolls back the user and first account when the second account is invalid" do
    accounts.first[:initialDeposit] = "10.00"
    accounts.last[:accountType] = "investment"

    expect { register(user: user, accounts: accounts) }
      .to change(User, :count).by(0)
      .and change(Account, :count).by(0)
      .and change(Transaction, :count).by(0)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
  end

  it "signs in with a multibyte password accepted at registration" do
    password = "é" * 65
    register(user: user.merge(password: password), accounts: accounts)

    post "/api/session", params: { session: { email: user[:email], password: password } },
      as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("user", "email")).to eq("taylor@example.test")
    get "/api/me", headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(user[:email], password) }
    expect(response).to have_http_status(:ok)
  end

  it "allows the new user to sign in and read only their accounts" do
    register(user: user, accounts: accounts)
    post "/api/session", params: { session: { email: user[:email], password: user[:password] } },
      as: :json

    expect(response).to have_http_status(:ok)
    get "/api/accounts", headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(user[:email], user[:password]) }
    expect(response.parsed_body.fetch("accounts").pluck("name")).to match_array(["Daily", "Rainy day"])
    expect(response.parsed_body.fetch("accounts").pluck("name")).not_to include("Everyday checking")
  end

  it "rejects malformed deposits without saving any row" do
    ["-1", "abc", "1.001"].each do |deposit|
      invalid_accounts = accounts.map(&:dup)
      invalid_accounts.last[:initialDeposit] = deposit
      expect { register(user: user, accounts: invalid_accounts) }
        .to change(User, :count).by(0)
        .and change(Account, :count).by(0)
        .and change(Transaction, :count).by(0)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_amount")
    end
  end

  it "requires at least one opening account" do
    expect { register(user: user, accounts: []) }.not_to change(User, :count)
    expect(response).to have_http_status(:bad_request)
  end

  it "rejects a blank account name without saving the user" do
    accounts.last[:name] = " "
    expect { register(user: user, accounts: accounts) }
      .to change(User, :count).by(0)
      .and change(Account, :count).by(0)
      .and change(Transaction, :count).by(0)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "requires a user name and password" do
    [user.merge(name: ""), user.merge(password: "")].each do |invalid_user|
      expect { register(user: invalid_user, accounts: accounts) }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "rejects duplicate email and preserves the existing user" do
    existing = users(:alex)
    expect { register(user: user.merge(email: existing.email), accounts: accounts) }
      .not_to change(User, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(existing.reload.name).to eq("Alex Morgan")
  end

  private

  def register(user:, accounts:)
    post "/api/users", params: { user: user, accounts: accounts }, as: :json
  end
end
