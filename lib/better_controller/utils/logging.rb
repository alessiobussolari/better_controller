# frozen_string_literal: true

module BetterController
  module Utils
    # Module providing logging capabilities
    module Logging
    extend ActiveSupport::Concern

    included do
      # Set up a logger for the controller
      class_attribute :better_controller_logger, default: Rails.logger if defined?(Rails)
    end

    # Log a message at the info level
    # @param message [String] The message to log
    # @param tags [Hash] Additional tags for the log
    def log_info(message, tags = {})
      log(:info, message, tags)
    end

    # Log a message at the debug level
    # @param message [String] The message to log
    # @param tags [Hash] Additional tags for the log
    def log_debug(message, tags = {})
      log(:debug, message, tags)
    end

    # Log a message at the warn level
    # @param message [String] The message to log
    # @param tags [Hash] Additional tags for the log
    def log_warn(message, tags = {})
      log(:warn, message, tags)
    end

    # Log a message at the error level
    # @param message [String] The message to log
    # @param tags [Hash] Additional tags for the log
    def log_error(message, tags = {})
      log(:error, message, tags)
    end

    # Log a message at the fatal level
    # @param message [String] The message to log
    # @param tags [Hash] Additional tags for the log
    def log_fatal(message, tags = {})
      log(:fatal, message, tags)
    end

    # Log an exception
    # @param exception [Exception] The exception to log
    # @param tags [Hash] Additional tags for the log
    def log_exception(exception, tags = {})
      return unless BetterController.config.error_handling[:log_errors]

      tags = tags.merge(
        exception_class: exception.class.name,
        backtrace:       exception.backtrace&.join("\n")
      )

      log_error(exception.message, tags)
    end

    private

    # Log a message at the specified level
    # @param level [Symbol] The log level
    # @param message [String] The message to log
    # @param tags [Hash] Additional tags for the log
    def log(level, message, tags = {})
      return unless logger

      tags = tags.merge(controller: self.class.name, action: action_name) if respond_to?(:action_name)

      if tags.empty?
        logger.send(level, message)
      else
        logger.send(level) { "[BetterController] #{message} #{tags.inspect}" }
      end
    end

    # Get the logger
    # @return [Logger] The logger
    def logger
      self.class.better_controller_logger
    end

    # Module providing class methods for logging
    module ClassMethods
      # Set the logger for the controller
      # @param logger [Logger] The logger to use
      def logger=(logger)
        self.better_controller_logger = logger
      end

      # Get the logger for the controller
      # @return [Logger] The logger
      def logger
        better_controller_logger
      end
    end
    end
  end
end
