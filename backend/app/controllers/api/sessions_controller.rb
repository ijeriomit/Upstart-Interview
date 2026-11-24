module Api
  class SessionsController < ApplicationController
    skip_before_action :require_signed_in, only: :create

    def create
      credentials = params.expect(session: [:email, :password])
      email, password = credentials.values_at(:email, :password)
      # This interview flow checks the mock password stored on the user row.
      if email.is_a?(String) && password.is_a?(String) && password.length <= 128
        user = User.find_by(email: email.strip.downcase, password: password)
      end
      return render_error(:unauthorized, "unauthorized", "Email or password is incorrect.") unless user

      # Sign-in verifies the mock credential; the browser keeps it for later
      # requests. No server-side session row or cookie is created.
      render json: { user: UserJson.call(user) }
    end
  end
end
