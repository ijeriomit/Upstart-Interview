require_relative "../rails_helper"

RSpec.describe Api::UsersController, type: :controller do
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
