class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection
  include Pundit::Authorization

  # Keep the request contract explicit. Rails otherwise wraps some flat JSON
  # bodies in a model key inferred from the controller name.
  wrap_parameters false

  # Check for a live session before checking the token on protected actions.
  before_action :no_store
  before_action :require_signed_in
  self.allow_forgery_protection = true
  self.forgery_protection_origin_check = true
  protect_from_forgery with: :exception

  # Convert lookup, authorization, and validation exceptions into the same
  # JSON error format across controllers.
  rescue_from ActiveRecord::RecordNotFound do
    render_error(:not_found, "not_found", "The requested record was not found.")
  end

  rescue_from Pundit::NotAuthorizedError do
    render_error(:forbidden, "forbidden", "You don't have access to this action.")
  end

  rescue_from ActionController::InvalidAuthenticityToken do
    render_error(:forbidden, "invalid_csrf_token", "Your form token expired. Please try again.")
  end

  rescue_from ActionController::ParameterMissing, ActionDispatch::Http::Parameters::ParseError do
    render_error(:bad_request, "bad_request", "Send a JSON object with the required parameters.")
  end

  rescue_from UsdAmount::Invalid do |error|
    render_error(:unprocessable_content, "invalid_amount", error.message)
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render_error(:unprocessable_content, "validation_failed", error.record.errors.full_messages.join(". "))
  end

  private

  def current_user_session
    if (session_id = session[:user_session_id])
      @current_user_session ||= UserSession.active.includes(:user).find_by(id: session_id)
    end
  end

  def current_user
    current_user_session&.user
  end

  def require_signed_in
    return if current_user

    render_error(:unauthorized, "unauthorized", "Sign in to continue.")
  end

  def render_error(status, code, message)
    render json: { error: { code: code, message: message } }, status: status
  end
end
