# frozen_string_literal: true

module BetterController
  module Controllers
    # Base module that provides core functionality for enhanced controllers
    module Base
      extend ActiveSupport::Concern

      included do
        # Class methods and configurations to be included in the controller
        class_attribute :better_controller_options, default: {}

        # Set up rescue handlers if enabled
        if defined?(rescue_from) && BetterController.config.error_handling[:detailed_errors]
          rescue_from StandardError, with: :better_controller_handle_error
        end
      end

      # Instance methods for controllers

      # Execute an action with enhanced error handling and response formatting
      # @param action_block [Proc] The block containing the action logic
      # @return [Object] The formatted response
      def execute_action(&)
        log_debug("Executing action: #{action_name}") if respond_to?(:action_name)
        result = instance_eval(&)
        respond_with_success(result)
      rescue StandardError => e
        handle_exception(e)
      end

      # Helper method to simplify common controller patterns
      # @param options [Hash] Options for the action
      # @return [Object] The result of the action
      def with_transaction(options = {}, &)
        ActiveRecord::Base.transaction(&)
      rescue StandardError => e
        handle_exception(e, options)
      end

      # Handle exceptions raised by the controller
      # @param exception [Exception] The exception to handle
      def better_controller_handle_error(exception)
        handle_exception(exception)
      end

      private

      # Handle exceptions in a standardized way
      # @param exception [Exception] The exception to handle
      # @param options [Hash] Options for handling the exception
      # @return [Object] The error response
      def handle_exception(exception, options = {})
        # Log the exception if logging is enabled
        if respond_to?(:log_exception) && BetterController.config.error_handling[:log_errors]
          log_exception(exception, { controller: self.class.name, action: action_name })
        end

        respond_with_error(exception, options)
      end
    end
  end
end
