# frozen_string_literal: true

# Example of a service class for User resources
class UserService < BetterController::Service
  protected

  # Define the resource class for this service
  def resource_class
    User
  end

  # Customize the resource scope if needed
  def resource_scope(ancestry_params = {})
    scope = super

    # Example of adding custom scoping
    scope = scope.active if ancestry_params[:active_only]

    scope
  end

  # Customize attribute preparation if needed
  def prepare_attributes(attributes, ancestry_params = {})
    prepared = super

    # Example of adding custom attribute preparation
    prepared[:created_by] = ancestry_params[:current_user_id] if ancestry_params[:current_user_id]

    prepared
  end
end
