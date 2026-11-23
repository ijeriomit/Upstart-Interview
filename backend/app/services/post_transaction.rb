class PostTransaction
  def self.call(account, attributes)
    amount = UsdAmount.parse(attributes[:amount])

    # with_lock starts a database transaction and reloads the account with a
    # PostgreSQL row lock. Other Puma workers and Rails processes must wait
    # for it too. A Ruby Mutex only coordinates threads in the same process.
    # requires_new also gives this operation its own savepoint if the caller
    # already has a transaction open, so a rescued failure rolls back both writes.
    account.with_lock(requires_new: true) do
      transaction = account.transactions.create!(
        direction: attributes[:direction], amount: amount, description: attributes[:description]
      )
      new_balance = transaction.direction == "credit" ? account.balance + amount : account.balance - amount
      account.update!(balance: new_balance)
      transaction
    end
  end
end
