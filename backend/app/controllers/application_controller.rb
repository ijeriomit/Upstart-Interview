class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include Pundit::Authorization

  # Keep the request contract explicit. Rails otherwise wraps some flat JSON
  # bodies in a model key inferred from the controller name.
  wrap_parameters false

  before_action :no_store
  before_action :require_signed_in

  # Convert lookup, authorization, and validation exceptions into the same
  # JSON error format across controllers.
  rescue_from ActiveRecord::RecordNotFound do
    render_error(:not_found, "not_found", "The requested record was not found.")
  end

  rescue_from Pundit::NotAuthorizedError do
    render_error(:forbidden, "forbidden", "You don't have access to this action.")
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

  def current_user
    return @current_user if defined?(@current_user)

    # This mock interview checks the supplied credentials on each request.
    # Pundit still receives the authenticated user, never a client-supplied ID.
    @current_user = authenticate_with_http_basic do |email, password|
      email = email.force_encoding(Encoding::UTF_8)
      password = password.force_encoding(Encoding::UTF_8)
      if email.valid_encoding? && password.valid_encoding? && password.length <= 128
        User.find_by(email: email.strip.downcase, password: password)
      end
    end
  end

  def require_signed_in
    return if current_user

    render_error(:unauthorized, "unauthorized", "Sign in to continue.")
  end

  def render_error(status, code, message)
    render json: { error: { code: code, message: message } }, status: status
  end
end
