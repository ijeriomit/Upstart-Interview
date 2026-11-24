module Api
  class UsersController < ApplicationController
    skip_before_action :require_signed_in, only: :create

    # POST /api/users creates every opening account and deposit in one database
    # transaction. Any invalid later row rolls back the earlier rows and user.
    def create
      user_attributes = params.expect(user: [:name, :email, :password])
      account_rows = params.require(:accounts)
      raise ActionController::ParameterMissing, :accounts unless account_rows.is_a?(Array) && account_rows.any?

      user = User.transaction do
        new_user = User.create!(user_attributes)
        account_rows.each do |row|
          raise ActionController::ParameterMissing, :accounts unless row.is_a?(ActionController::Parameters)

          attributes = row.permit(:name, :accountType, :initialDeposit)
          amount = UsdAmount.parse(attributes[:initialDeposit])
          account = new_user.accounts.create!(name: attributes[:name], account_type: attributes[:accountType])
          PostTransaction.call(account, direction: "credit", amount: attributes[:initialDeposit], description: "Opening deposit") if amount.positive?
        end
        new_user
      end

      render json: { user: UserJson.call(user) }, status: :created
    end

    # GET /api/me returns the identity from the authenticated session.
    # Check the supplied ID, or the supplied email when the ID is omitted.
    def show
      user_id = current_user.id.to_s
      if params.key?(:id)
        raise Pundit::NotAuthorizedError unless params[:id] == user_id
      elsif params.key?(:email)
        raise Pundit::NotAuthorizedError unless params[:email] == current_user.email
      end

      render json: { user: UserJson.call(current_user) }
    end
  end
end
