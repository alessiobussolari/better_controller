# frozen_string_literal: true

module BetterController
  # Configuration module for BetterController
  module Configuration
    # Default configuration options
    DEFAULTS = {
      pagination:     {
        enabled:  true,
        per_page: 25,
      },
      serialization:  {
        include_root:  false,
        camelize_keys: true,
      },
      error_handling: {
        log_errors:      true,
        detailed_errors: true,
      },
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
  end
end
