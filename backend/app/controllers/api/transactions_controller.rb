module Api
  class TransactionsController < ApplicationController
    # After the action completes, Pundit checks for an authorize call and a
    # policy_scope call. One policy_scope call satisfies the scope callback.
    after_action :verify_authorized
    after_action :verify_policy_scoped

    def create
      # account_id comes from the route. The account scope makes both missing
      # accounts and accounts owned by someone else return 404.
      account = policy_scope(Account).find(params[:account_id])
      # Pundit uses the create action's name to call TransactionPolicy#create?
      # with this unsaved transaction. The permission check precedes the write.
      authorize Transaction.new(account: account)
      # Require a transaction object and accept only these fields from its body.
      attributes = params.expect(transaction: [:direction, :amount, :description])

      PostTransaction.call(account, attributes)
      # Return the updated balance, totals, and history using the scoped relation.
      render json: AccountSummary.call(account, policy_scope(account.transactions)), status: :created
    end
  end
end
