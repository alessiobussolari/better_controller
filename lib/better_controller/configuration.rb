# frozen_string_literal: true

module BetterController
  # Configuration module for BetterController
  module Configuration
    # Default configuration options
    DEFAULTS = {
      pagination:              {
        enabled:  true,
        per_page: 25
      },
      serialization:           {
        include_root:  false,
        camelize_keys: true
      },
      error_handling:          {
        log_errors:      true,
        detailed_errors: true
      },
      html:                    {
        page_component_namespace: 'Templates',
        flash_partial:            'shared/flash',
        form_errors_partial:      'shared/form_errors'
      },
      turbo:                   {
        enabled:               true,
        default_frame:         nil,
        auto_flash:            true,
        auto_form_errors:      true
      }
    }.freeze

    class << self
      # Get the current configuration
      # @return [Hash] The current configuration
      def options
        @options ||= DEFAULTS.deep_dup
      end

      # Configure BetterController
      # @yield [config] The configuration block
      def configure
        yield(options) if block_given?
      end

      # Reset the configuration to defaults
      def reset!
        @options = DEFAULTS.deep_dup
      end

      # Get a specific configuration option
      # @param key [Symbol] The configuration key
      # @return [Object] The configuration value
      delegate :[], to: :options

      # Set a specific configuration option
      # @param key [Symbol] The configuration key
      # @param value [Object] The configuration value
      delegate :[]=, to: :options
    end

    # Get the pagination configuration
    # @return [Hash] The pagination configuration
    def self.pagination
      options[:pagination]
    end

    # Get the serialization configuration
    # @return [Hash] The serialization configuration
    def self.serialization
      options[:serialization]
    end

    # Get the error handling configuration
    # @return [Hash] The error handling configuration
    def self.error_handling
      options[:error_handling]
    end

    # Get the HTML configuration
    # @return [Hash] The HTML configuration
    def self.html
      options[:html]
    end

    # Get the Turbo configuration
    # @return [Hash] The Turbo configuration
    def self.turbo
      options[:turbo]
    end

    # Get the page component namespace
    # @return [String] The namespace for page components
    def self.page_component_namespace
      html[:page_component_namespace]
    end

    # Get the flash partial path
    # @return [String] The flash partial path
    def self.flash_partial
      html[:flash_partial]
    end

    # Get the form errors partial path
    # @return [String] The form errors partial path
    def self.form_errors_partial
      html[:form_errors_partial]
    end

    # Check if Turbo is enabled
    # @return [Boolean] Whether Turbo is enabled
    def self.turbo_enabled?
      turbo[:enabled]
    end
  end
end
