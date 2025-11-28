# frozen_string_literal: true

# BetterController Configuration
BetterController.configure do |config|
  # Pagination configuration
  config[:pagination] = {
    # Enable pagination for ResourcesController
    enabled:  true,
    # Default number of items per page
    per_page: 25
  }

  # Serialization configuration
  config[:serialization] = {
    # Include root key in JSON response
    include_root:  false,
    # Camelize keys in JSON response
    camelize_keys: true
  }

  # Error handling configuration
  config[:error_handling] = {
    # Log errors to Rails logger
    log_errors:      true,
    # Include detailed error information in responses
    detailed_errors: Rails.env.development?
  }

  # HTML/ViewComponent configuration
  config[:html] = {
    # Namespace for page components (e.g., Templates::Index::PageComponent)
    page_component_namespace: 'Templates',
    # Partial for flash messages in Turbo Stream responses
    flash_partial:            'shared/flash',
    # Partial for form errors in Turbo Stream responses
    form_errors_partial:      'shared/form_errors'
  }

  # Turbo configuration
  config[:turbo] = {
    # Enable Turbo support
    enabled:          true,
    # Default Turbo Frame ID (nil = auto-detect)
    default_frame:    nil,
    # Automatically update flash in Turbo Stream responses
    auto_flash:       true,
    # Automatically update form errors in Turbo Stream responses
    auto_form_errors: true
  }
end

# Optional: Configure custom logger
# BetterController::Logging.logger = Rails.logger
