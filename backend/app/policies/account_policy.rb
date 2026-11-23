class AccountPolicy
  def initialize(user, account)
    @user = user
    @account = account
  end

  def show?
    @account.user_id == @user.id
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # A scope returns a relation, so ordering and lookups still happen in SQL.
    def resolve
      @scope.where(user_id: @user.id)
    end
  end
end
