class AccountPolicy
  def initialize(user, account)
    @user = user
    @account = account
  end

  # Pundit calls this predicate when the show action authorizes an account.
  def show?
    @account.user_id == @user.id
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # Restrict the relation to accounts owned by the current user. The
    # controller can add ordering or a lookup and execute it all in SQL.
    def resolve
      @scope.where(user_id: @user.id)
    end
  end
end
