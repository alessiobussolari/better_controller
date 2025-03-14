# frozen_string_literal: true

class <%= service_class_name %> < BetterController::Service
  # Define the model class for this service
  def model_class
    <%= model_class_name %>
  end

  # Define the permitted attributes for create and update operations
  def permitted_attributes
    [
      # Add your permitted attributes here
      # Examples:
      # :name,
      # :email,
      # { address_attributes: [:street, :city, :state, :zip] }
    ]
  end

  # Optional: Override the default query for finding resources
  # def find_query(id)
  #   model_class.includes(:associations).find(id)
  # end

  # Optional: Override the default query for listing resources
  # def list_query
  #   model_class.includes(:associations).all
  # end

  # Optional: Add custom validation before create
  # def validate_create(attributes)
  #   # Add your validation logic here
  #   # Raise BetterController::Error.new("Custom error message") if validation fails
  # end

  # Optional: Add custom validation before update
  # def validate_update(resource, attributes)
  #   # Add your validation logic here
  #   # Raise BetterController::Error.new("Custom error message") if validation fails
  # end

  # Optional: Add custom logic after create
  # def after_create(resource)
  #   # Add your after create logic here
  # end

  # Optional: Add custom logic after update
  # def after_update(resource)
  #   # Add your after update logic here
  # end

  # Optional: Add custom logic before destroy
  # def before_destroy(resource)
  #   # Add your before destroy logic here
  #   # Return false to prevent destruction
  # end
end
