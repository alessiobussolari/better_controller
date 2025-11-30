# frozen_string_literal: true

module BetterController
  module Controllers
    # Module providing helper methods for standardized API responses
    #
    # Response format:
    #   {
    #     "data": { ... },
    #     "meta": { "version": "v1", ... }
    #   }
    #
    module ResponseHelpers
      extend ActiveSupport::Concern

      # Respond with a success response
      # @param data [Object] The data to include in the response
      # @param status [Symbol, Integer] The HTTP status code
      # @param meta [Hash] Additional metadata for the response
      # @return [Object] The formatted response
      def respond_with_success(data = nil, status: :ok, meta: {})
        response = build_response(data, meta)

        if defined?(render)
          render json: response, status: status
        else
          response
        end
      end

      # Respond with an error response
      # @param error [Exception, String, Hash, ActiveModel::Errors] The error or error message
      # @param status [Symbol, Integer] The HTTP status code
      # @param meta [Hash] Additional metadata for the response
      # @return [Object] The formatted error response
      def respond_with_error(error = nil, status: :unprocessable_entity, meta: {})
        error_data = { error: format_error(error) }
        response = build_response(error_data, meta)

        if defined?(render)
          render json: response, status: status
        else
          response
        end
      end

      private

      # Build the standard response structure
      # @param data [Object] The data to include
      # @param meta [Hash] Additional metadata
      # @return [Hash] The formatted response
      def build_response(data, meta = {})
        {
          data: data,
          meta: { version: BetterController.config.api_version }.merge(meta)
        }
      end

      # Format error into a standardized structure
      # @param error [Exception, String, Hash, ActiveModel::Errors] The error
      # @return [Hash] Formatted error hash
      def format_error(error)
        case error
        when Exception
          { type: error.class.name, message: error.message }
        when Hash
          error
        when String
          { message: error }
        else
          # Handle ActiveModel::Errors or similar
          if error.respond_to?(:full_messages)
            { messages: error.full_messages, details: error.to_hash }
          elsif error.respond_to?(:to_hash)
            error.to_hash
          else
            { message: error.to_s }
          end
        end
      end
    end
  end
end
