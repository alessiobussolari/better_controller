# frozen_string_literal: true

module BetterController
  module Utils
    # Module providing parameter validation helpers for controllers
    module ParameterValidation
      extend ActiveSupport::Concern

      # Class methods for parameter validation
      module ClassMethods
        # Define required parameters for an action
        # @param action_name [Symbol] The name of the action
        # @param params [Array<Symbol>] The required parameters
        def requires_params(action_name, *params)
          before_action only: action_name do
            validate_required_params(*params)
          end
        end

        # Define parameter schema for an action
        # @param action_name [Symbol] The name of the action
        # @param schema [Hash] The parameter schema
        def param_schema(action_name, schema)
          before_action only: action_name do
            validate_param_schema(schema)
          end
        end
      end

      # Instance methods for parameter validation

      # Validate that required parameters are present
      # @param params [Array<Symbol>] The required parameters
      # @raise [BetterController::Error] If a required parameter is missing
      def validate_required_params(*params)
        missing_params = []

        params.each do |param|
          missing_params << param unless parameter_present?(param)
        end

        unless missing_params.empty?
          error_message = "Missing required parameters: #{missing_params.join(', ')}"
          raise BetterController::Error, error_message
        end

        true
      end

      # Validate parameters against a schema
      # @param schema [Hash] The parameter schema
      # @raise [BetterController::Error] If parameters don't match the schema
      def validate_param_schema(schema)
        errors = []

        schema.each do |param, rules|
          value = params[param]

          if rules[:required] && value.nil?
            errors << "#{param} is required"
            next
          end

          next if value.nil?

          errors << "#{param} must be a #{rules[:type]}" if rules[:type] && !value.is_a?(rules[:type])

          errors << "#{param} must be one of: #{rules[:in].join(', ')}" if rules[:in]&.exclude?(value)

          errors << "#{param} has invalid format" if rules[:format] && rules[:format] !~ value.to_s
        end

        raise BetterController::Error, errors.join(', ') unless errors.empty?

        true
      end

      private

      # Check if a parameter is present
      # @param param [Symbol] The parameter to check
      # @return [Boolean] Whether the parameter is present
      def parameter_present?(param)
        params.key?(param.to_s) || params.key?(param.to_sym)
      end
    end
  end
end
