# frozen_string_literal: true

# Example of an API controller using BetterController
class ApiController < ActionController::API
  include BetterController

  # Global error handling for API controllers
  rescue_from ActiveRecord::RecordNotFound do |exception|
    respond_with_error(exception, status: :not_found)
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    respond_with_error(exception, status: :unprocessable_entity)
  end

  # Helper method for authentication
  def authenticate_api_user!
    token = request.headers['Authorization']&.split&.last

    return if valid_token?(token)

    respond_with_error('Unauthorized access', status: :unauthorized)
  end

  private

  def valid_token?(token)
    # Implementation of token validation logic
    token.present? && ApiToken.exists?(token: token)
  end
end
