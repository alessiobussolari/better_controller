# frozen_string_literal: true

module BetterController
  module Errors
    # Error raised when a service returns a failed Result
    #
    # This error is automatically raised by the controller when unwrapping
    # a Result object with meta[:success] == false
    #
    class ServiceError < StandardError
      attr_reader :resource, :meta

      # @param resource [Object] The resource from the failed operation
      # @param meta [Hash] The metadata from the failed operation
      def initialize(resource, meta)
        @resource = resource
        @meta     = meta || {}
        super(@meta[:message] || 'Operation failed')
      end

      # @return [ActiveModel::Errors, Hash, nil] Errors from resource
      def errors
        return resource.errors.to_hash if resource.respond_to?(:errors)

        nil
      end
    end
  end
end
