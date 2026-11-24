class AccountJson
  # Build the account fields shared by the list and detail responses. IDs and
  # balances are strings in the API so clients can preserve them exactly.
  def self.call(account)
    {
      id: account.id.to_s,
      name: account.name,
      balance: UsdAmount.as_json_string(account.balance)
    }
  end
end
