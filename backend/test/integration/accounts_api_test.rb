require "test_helper"

class AccountsApiTest < ActionDispatch::IntegrationTest
  setup do
    @previous_demo_user = ENV["DEMO_USER_EMAIL"]
    ENV["DEMO_USER_EMAIL"] = users(:alex).email
  end

  teardown do
    ENV["DEMO_USER_EMAIL"] = @previous_demo_user
  end

  test "shows the configured user and ignores client-supplied identity" do
    get "/api/me", headers: { "X-User-ID" => users(:jordan).id.to_s }

    assert_response :ok
    assert_equal users(:alex).id.to_s, response.parsed_body.dig("user", "id")
  end

  test "requires a configured demo user" do
    ENV["DEMO_USER_EMAIL"] = "absent@example.test"
    get api_accounts_path

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body.dig("error", "code")
  end

  test "lists only the current user's accounts and scopes their transactions" do
    get api_accounts_path
    assert_response :ok
    assert_equal [accounts(:checking).id.to_s, accounts(:savings).id.to_s],
      response.parsed_body.fetch("accounts").pluck("id")

    visible_transactions = Pundit.policy_scope!(users(:alex), Transaction)
    assert_equal [transactions(:deposit).id, transactions(:payment).id].sort, visible_transactions.pluck(:id).sort
  end

  test "shows exact totals and newest transactions first" do
    get api_account_path(accounts(:checking))

    assert_response :ok
    summary = response.parsed_body
    assert_equal "10.10", summary.dig("account", "balance")
    assert_equal "12.35", summary.fetch("totalCredits")
    assert_equal "2.25", summary.fetch("totalDebits")
    assert_equal [transactions(:payment).id.to_s, transactions(:deposit).id.to_s],
      summary.fetch("transactions").pluck("id")
  end

  test "posts credits and debits and updates the balance exactly" do
    account = accounts(:checking)
    assert_difference "Transaction.count", 2 do
      post_entry(account, direction: "credit", amount: "0.20")
      assert_response :created
      assert_equal "10.30", response.parsed_body.dig("account", "balance")

      post_entry(account, direction: "debit", amount: "0.10")
      assert_response :created
      assert_equal "10.20", response.parsed_body.dig("account", "balance")
    end

    assert_equal BigDecimal("10.20"), account.reload.balance
  end

  test "rejects JSON numbers, excessive scale, and invalid directions without writing" do
    account = accounts(:checking)
    assert_no_difference "Transaction.count" do
      [0.20, "0.201"].each do |amount|
        post_entry(account, direction: "credit", amount: amount)
        assert_response 422
        assert_equal "invalid_amount", response.parsed_body.dig("error", "code")
      end

      post_entry(account, direction: "transfer", amount: "0.20")
      assert_response 422
      assert_equal "validation_failed", response.parsed_body.dig("error", "code")
    end
    assert_equal BigDecimal("10.10"), account.reload.balance
  end

  test "rolls back the transaction row when the balance update is invalid" do
    account = accounts(:checking)
    assert_no_difference "Transaction.count" do
      post_entry(account, direction: "debit", amount: "10.11")
      assert_response 422
      assert_equal "validation_failed", response.parsed_body.dig("error", "code")
    end
    assert_equal BigDecimal("10.10"), account.reload.balance
  end

  test "cannot read or write another user's account" do
    other_account = accounts(:personal)
    get api_account_path(other_account)
    assert_response :not_found
    assert_equal "not_found", response.parsed_body.dig("error", "code")

    assert_no_difference "Transaction.count" do
      post_entry(other_account, direction: "credit", amount: "1.00")
      assert_response :not_found
      assert_equal "not_found", response.parsed_body.dig("error", "code")
    end
    assert_equal BigDecimal("50.00"), other_account.reload.balance
  end

  test "requires a transaction object" do
    post api_account_transactions_path(accounts(:checking)), params: { amount: "1.00" }, as: :json
    assert_response :bad_request
    assert_equal "bad_request", response.parsed_body.dig("error", "code")
  end

  private

  def post_entry(account, **attributes)
    post api_account_transactions_path(account), params: { transaction: attributes }, as: :json
  end
end
