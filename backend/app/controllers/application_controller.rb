class ApplicationController < ActionController::API
  include Pundit::Authorization

  # Keep the request contract explicit. Rails otherwise wraps some flat JSON
  # bodies in a model key inferred from the controller name.
  wrap_parameters false

  before_action :load_demo_user

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

  # Pundit calls current_user when it constructs policies and scopes. The
  # server chooses the demo identity so the browser cannot impersonate a user.
  attr_reader :current_user

  def load_demo_user
    if Rails.env.development? || Rails.env.test?
      @current_user = User.find_by(email: ENV.fetch("DEMO_USER_EMAIL", "alex@example.test"))
    end

    return if current_user

    render_error(:unauthorized, "unauthorized", "No current user is configured.")
  end

  def render_error(status, code, message)
    render json: { error: { code: code, message: message } }, status: status
  end
end
