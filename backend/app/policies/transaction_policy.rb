class TransactionPolicy
  def initialize(user, transaction)
    @user = user
    @transaction = transaction
  end

  def create?
    @transaction.account.user_id == @user.id
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      @scope.where(account: @user.accounts)
    end
  end
end
