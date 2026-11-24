class TransactionPolicy
  def initialize(user, transaction)
    @user = user
    @transaction = transaction
  end

  # The controller authorizes an unsaved transaction linked to the target account.
  def create?
    @transaction.account.user_id == @user.id
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # Add an ownership filter to the incoming relation. If it already selects
    # transactions for one account, that filter still applies.
    def resolve
      @scope.where(account: @user.accounts)
    end
  end
end
