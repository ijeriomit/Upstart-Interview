module Api
  class UsersController < ApplicationController
    # GET /api/me returns the identity loaded by ApplicationController.
    # Check the supplied ID, or the supplied email when the ID is omitted.
    def show
      user_id = current_user.id.to_s
      if params.key?(:id)
        raise Pundit::NotAuthorizedError unless params[:id] == user_id
      elsif params.key?(:email)
        raise Pundit::NotAuthorizedError unless params[:email] == current_user.email
      end

      render json: { user: { id: user_id, name: current_user.name, email: current_user.email } }
    end
  end
end
