module Api
  class AccountsController < ApplicationController
    # Pundit checks that both actions use policy_scope and that show also calls
    # authorize for the requested account.
    after_action :verify_policy_scoped
    after_action :verify_authorized, only: :show

    def index
      # Filter to the current user's accounts before sorting in the database.
      # Each row becomes a small JSON summary for the account list.
      accounts = policy_scope(Account).order(:name, :id)
      render json: { accounts: accounts.map { |account| AccountJson.call(account) } }
    end

    def show
      # Finding through the scope gives the same 404 for missing accounts and
      # accounts owned by someone else. authorize calls AccountPolicy#show?
      # and returns the account when access is granted.
      account = authorize policy_scope(Account).find(params[:id])
      # Apply the transaction policy to this account's history before summarizing it.
      render json: AccountSummary.call(account, policy_scope(account.transactions))
    end
  end
end
