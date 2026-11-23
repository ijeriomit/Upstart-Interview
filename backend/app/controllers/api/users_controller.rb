module Api
  class UsersController < ApplicationController
    def show
      render json: { user: { id: current_user.id.to_s, name: current_user.name, email: current_user.email } }
    end
  end
end
