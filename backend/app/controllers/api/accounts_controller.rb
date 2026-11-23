module Api
  class AccountsController < ApplicationController
    after_action :verify_policy_scoped
    after_action :verify_authorized, only: :show

    def index
      accounts = policy_scope(Account).order(:name, :id)
      render json: { accounts: accounts.map { |account| AccountJson.call(account) } }
    end

    def show
      # Finding through the scope gives the same 404 for missing accounts and
      # accounts owned by someone else. authorize checks the individual action.
      account = authorize policy_scope(Account).find(params[:id])
      render json: AccountSummary.call(account, policy_scope(account.transactions))
    end
  end
end
