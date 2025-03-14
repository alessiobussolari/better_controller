# frozen_string_literal: true

require_relative 'user_service'
require_relative 'user_serializer'

# Example of a Rails controller using BetterController::ResourcesController
class UsersController < ApplicationController
  include BetterController::ResourcesController

  # Define required parameters for actions
  requires_params :create, :name, :email
  requires_params :update, :id

  # Define parameter schema for validation
  param_schema :create, {
    name:  { required: true, type: String },
    email: { required: true, format: /\A[^@\s]+@[^@\s]+\z/ },
    role:  { in: %w[admin user guest] },
  }

  # You can override any of the ResourcesController methods if needed
  # For example, to customize the index action:
  def index
    execute_action do
      @resource_collection = resource_collection_resolver

      # Add pagination metadata
      if @resource_collection.respond_to?(:page)
        paginated            = @resource_collection.page(params[:page] || 1).per(params[:per_page] || 25)
        add_meta(:pagination, {
                   current_page: paginated.current_page,
                   total_pages:  paginated.total_pages,
                   total_count:  paginated.total_count,
                 })
        @resource_collection = paginated
      end

      respond_with_success(@resource_collection, options: { meta: meta })
    end
  end

  # You can also add custom actions
  def activate
    execute_action do
      @resource = resource_finder
      @resource.update(active: true)

      respond_with_success(@resource, options: {
                             message: "User #{@resource.name} has been activated",
                           })
    end
  end

  protected

  # Define the resource service class
  def resource_service_class
    UserService
  end

  # Define the root key for resource parameters
  def resource_params_root_key
    :user
  end

  # Customize the ancestry parameters if needed
  def ancestry_key_params
    # Example: passing the current user ID to the service
    { current_user_id: current_user&.id }
  end

  # Customize create message
  def create_message
    "User #{@resource.name} has been created successfully"
  end

  # Customize update message
  def update_message
    "User #{@resource.name} has been updated successfully"
  end

  # Customize destroy message
  def destroy_message
    'User has been deleted successfully'
  end
end
