# frozen_string_literal: true

# BetterController Configuration (Kaminari-style)
BetterController.configure do |config|
  # ============================================================================
  # Pagination
  # ============================================================================

  # Enable pagination for ResourcesController
  config.pagination_enabled = true

  # Default number of items per page
  config.pagination_per_page = 25

  # ============================================================================
  # Serialization
  # ============================================================================

  # Include root key in JSON response
  config.serialization_include_root = false

  # Camelize keys in JSON response
  config.serialization_camelize_keys = true

  # ============================================================================
  # Error Handling
  # ============================================================================

  # Log errors to Rails logger
  config.error_handling_log_errors = true

  # Include detailed error information in responses
  config.error_handling_detailed_errors = Rails.env.development?

  # ============================================================================
  # HTML / ViewComponent
  # ============================================================================

  # Namespace for page components (e.g., Templates::Index::PageComponent)
  config.html_page_component_namespace = 'Templates'

  # Partial for flash messages in Turbo Stream responses
  config.html_flash_partial = 'shared/flash'

  # Partial for form errors in Turbo Stream responses
  config.html_form_errors_partial = 'shared/form_errors'

  # ============================================================================
  # Turbo
  # ============================================================================

  # Enable Turbo support
  config.turbo_enabled = true

  # Default Turbo Frame ID (nil = auto-detect)
  config.turbo_default_frame = nil

  # Automatically update flash in Turbo Stream responses
  config.turbo_auto_flash = true

  # Automatically update form errors in Turbo Stream responses
  config.turbo_auto_form_errors = true

  # ============================================================================
  # Wrapped Responses (Service/Command Results)
  # ============================================================================

  # Enable wrapped response handling by setting a Result class.
  # The class must implement: #resource, #meta (Hash with :success key)
  #
  # Default: nil (disabled - services return resources directly)
  #
  # To enable with the built-in Result class:
  # config.wrapped_responses_class = BetterController::Result
  #
  # Or use a custom class (e.g., from BetterService gem):
  # config.wrapped_responses_class = BetterService::Result
  #
  # Example usage in a service:
  #   BetterController::Result.new(user, meta: { message: 'Created' })
  #   BetterController::Result.new(user, meta: { success: false, message: 'Failed' })
  #
  config.wrapped_responses_class = nil
end

# Optional: Configure custom logger
# BetterController::Logging.logger = Rails.logger
