# frozen_string_literal: true

module BetterController
  # Configuration class for BetterController (Kaminari-style)
  #
  # @example Configure in initializer
  #   BetterController.configure do |config|
  #     config.pagination_enabled = true
  #     config.pagination_per_page = 25
  #     config.wrapped_responses_class = BetterController::Result
  #   end
  #
  class Configuration
    # Pagination
    attr_accessor :pagination_enabled, :pagination_per_page

    # Serialization
    attr_accessor :serialization_include_root, :serialization_camelize_keys

    # Error handling
    attr_accessor :error_handling_log_errors, :error_handling_detailed_errors

    # HTML
    attr_accessor :html_page_component_namespace, :html_flash_partial, :html_form_errors_partial

    # Turbo
    attr_accessor :turbo_enabled, :turbo_default_frame, :turbo_auto_flash, :turbo_auto_form_errors

    # Wrapped Responses
    attr_accessor :wrapped_responses_class

    # Page Config
    attr_accessor :page_config_class

    # API Version
    attr_accessor :api_version

    def initialize
      # Pagination defaults
      @pagination_enabled  = true
      @pagination_per_page = 25

      # Serialization defaults
      @serialization_include_root  = false
      @serialization_camelize_keys = true

      # Error handling defaults
      @error_handling_log_errors      = true
      @error_handling_detailed_errors = true

      # HTML defaults
      @html_page_component_namespace = 'Templates'
      @html_flash_partial            = 'shared/flash'
      @html_form_errors_partial      = 'shared/form_errors'

      # Turbo defaults
      @turbo_enabled          = true
      @turbo_default_frame    = nil
      @turbo_auto_flash       = true
      @turbo_auto_form_errors = true

      # Wrapped responses default (nil = disabled, use BetterController::Result to enable)
      @wrapped_responses_class = nil

      # Page config default (nil = use BetterController::Config, set to BetterPage::Config to use external gem)
      @page_config_class = nil

      # API version default
      @api_version = 'v1'
    end

    # Legacy Hash-style access for backward compatibility
    # @return [Hash] Configuration as hash
    def to_h
      {
        pagination:        {
          enabled:  pagination_enabled,
          per_page: pagination_per_page,
        },
        serialization:     {
          include_root:  serialization_include_root,
          camelize_keys: serialization_camelize_keys,
        },
        error_handling:    {
          log_errors:      error_handling_log_errors,
          detailed_errors: error_handling_detailed_errors,
        },
        html:              {
          page_component_namespace: html_page_component_namespace,
          flash_partial:            html_flash_partial,
          form_errors_partial:      html_form_errors_partial,
        },
        turbo:             {
          enabled:          turbo_enabled,
          default_frame:    turbo_default_frame,
          auto_flash:       turbo_auto_flash,
          auto_form_errors: turbo_auto_form_errors,
        },
        wrapped_responses: {
          class: wrapped_responses_class,
        },
      }
    end

    # Legacy Hash-style getter for backward compatibility
    def [](key)
      case key
      when :pagination
        { enabled: pagination_enabled, per_page: pagination_per_page }
      when :serialization
        { include_root: serialization_include_root, camelize_keys: serialization_camelize_keys }
      when :error_handling
        { log_errors: error_handling_log_errors, detailed_errors: error_handling_detailed_errors }
      when :html
        {
          page_component_namespace: html_page_component_namespace,
          flash_partial:            html_flash_partial,
          form_errors_partial:      html_form_errors_partial,
        }
      when :turbo
        {
          enabled:          turbo_enabled,
          default_frame:    turbo_default_frame,
          auto_flash:       turbo_auto_flash,
          auto_form_errors: turbo_auto_form_errors,
        }
      end
    end

    # Legacy Hash-style setter for backward compatibility
    def []=(key, value)
      case key
      when :pagination
        self.pagination_enabled  = value[:enabled] if value.key?(:enabled)
        self.pagination_per_page = value[:per_page] if value.key?(:per_page)
      when :serialization
        self.serialization_include_root  = value[:include_root] if value.key?(:include_root)
        self.serialization_camelize_keys = value[:camelize_keys] if value.key?(:camelize_keys)
      when :error_handling
        self.error_handling_log_errors      = value[:log_errors] if value.key?(:log_errors)
        self.error_handling_detailed_errors = value[:detailed_errors] if value.key?(:detailed_errors)
      when :html
        self.html_page_component_namespace = value[:page_component_namespace] if value.key?(:page_component_namespace)
        self.html_flash_partial            = value[:flash_partial] if value.key?(:flash_partial)
        self.html_form_errors_partial      = value[:form_errors_partial] if value.key?(:form_errors_partial)
      when :turbo
        self.turbo_enabled          = value[:enabled] if value.key?(:enabled)
        self.turbo_default_frame    = value[:default_frame] if value.key?(:default_frame)
        self.turbo_auto_flash       = value[:auto_flash] if value.key?(:auto_flash)
        self.turbo_auto_form_errors = value[:auto_form_errors] if value.key?(:auto_form_errors)
      end
    end

    # Convenience accessors for grouped configs (backward compatibility)

    def pagination
      self[:pagination]
    end

    def serialization
      self[:serialization]
    end

    def error_handling
      self[:error_handling]
    end

    def html
      self[:html]
    end

    def turbo
      self[:turbo]
    end

    def page_component_namespace
      html_page_component_namespace
    end

    def flash_partial
      html_flash_partial
    end

    def form_errors_partial
      html_form_errors_partial
    end

    def turbo_enabled?
      turbo_enabled
    end

    # Check if wrapped responses are enabled
    # @return [Boolean]
    def wrapped_responses_enabled?
      !wrapped_responses_class.nil?
    end

    # Check if custom page config class is enabled
    # @return [Boolean]
    def page_config_class_enabled?
      !page_config_class.nil?
    end
  end
end
