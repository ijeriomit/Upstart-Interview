module Api
  class TransactionsController < ApplicationController
    after_action :verify_authorized
    after_action :verify_policy_scoped

    def create
      account = policy_scope(Account).find(params[:account_id])
      authorize Transaction.new(account: account)
      attributes = params.expect(transaction: [:direction, :amount, :description])

      PostTransaction.call(account, attributes)
      render json: AccountSummary.call(account, policy_scope(account.transactions)), status: :created
    end
  end
end
