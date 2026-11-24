module Api
  class SessionsController < ApplicationController
    skip_before_action :require_signed_in, only: [:csrf, :create]

    def csrf
      render json: { csrfToken: form_authenticity_token }
    end

    def create
      credentials = params.expect(session: [:email, :password])
      email, password = credentials.values_at(:email, :password)
      if email.is_a?(String) && password.is_a?(String) && password.bytesize <= ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED
        user = User.where.not(password_digest: nil).authenticate_by(email: email, password: password)
      end
      return render_error(:unauthorized, "unauthorized", "Email or password is incorrect.") unless user

      user_session = UserSession.transaction do
        current_user_session&.destroy!
        user.user_sessions.create!
      end
      reset_session
      session[:user_session_id] = user_session.id

      render json: { user: { id: user.id.to_s, name: user.name, email: user.email } }
    end

    def destroy
      current_user_session.destroy!
      reset_session
      # Expire the cookie instead of letting CookieStore write an anonymous session.
      request.session_options[:skip] = true
      request.cookie_jar.delete(Rails.application.config.session_options.fetch(:key))
      head :no_content
    end
  end
end
