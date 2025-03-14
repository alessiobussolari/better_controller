# frozen_string_literal: true

# BetterController Configuration
BetterController.configure do |config|
  # Pagination configuration
  config[:pagination] = {
    # Enable pagination for ResourcesController
    enabled:  true,
    # Default number of items per page
    per_page: 25,
  }

  # Serialization configuration
  config[:serialization] = {
    # Include root key in JSON response
    include_root:  false,
    # Camelize keys in JSON response
    camelize_keys: true,
  }

  # Error handling configuration
  config[:error_handling] = {
    # Log errors to Rails logger
    log_errors:      true,
    # Include detailed error information in responses
    detailed_errors: true,
  }
end

# Optional: Configure custom logger
# BetterController::Logging.logger = Rails.logger
