class AccountJson
  def self.call(account)
    {
      id: account.id.to_s,
      name: account.name,
      balance: UsdAmount.as_json_string(account.balance)
    }
  end
end
