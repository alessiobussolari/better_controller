# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include BetterController

  # Handle common exceptions with custom responses
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  protected

  # Handle record not found errors
  def handle_not_found(exception)
    log_exception(exception)
    respond_with_error(
      message: 'Resource not found',
      details: exception.message,
      status:  :not_found
    )
  end

  # Handle validation errors
  def handle_validation_error(exception)
    log_exception(exception)
    respond_with_error(
      message: 'Validation failed',
      details: exception.record.errors.full_messages,
      status:  :unprocessable_entity
    )
  end

  # Handle missing parameters
  def handle_parameter_missing(exception)
    log_exception(exception)
    respond_with_error(
      message: 'Missing parameter',
      details: exception.message,
      status:  :bad_request
    )
  end

  # Add custom metadata to responses
  def meta
    {
      app_version: '1.0.0',
      api_version: 'v1',
      timestamp:   Time.current,
    }
  end
end
