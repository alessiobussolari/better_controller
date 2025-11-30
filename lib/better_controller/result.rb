# frozen_string_literal: true

module BetterController
  # Result wrapper for service/command responses
  #
  # Provides a standardized way to return both resource and metadata from services.
  # The controller automatically unwraps Result objects and handles success/failure.
  #
  # @example Success case
  #   BetterController::Result.new(user, meta: { message: "Created" })
  #
  # @example Failure case
  #   BetterController::Result.new(user, meta: { success: false, message: "Validation failed" })
  #
  class Result
    attr_reader :resource, :meta

    # @param resource [Object] The resource object (model, collection, etc.)
    # @param meta [Hash] Metadata hash, must contain :success key (defaults to true)
    def initialize(resource, meta: {})
      @resource = resource
      @meta     = meta.is_a?(Hash) ? meta.reverse_merge(success: true) : { success: true }
    end

    # @return [Boolean] true if operation was successful
    def success?
      meta[:success] == true
    end

    # @return [Boolean] true if operation failed
    def failure?
      !success?
    end

    # @return [String, nil] The message from meta
    def message
      meta[:message]
    end

    # @return [ActiveModel::Errors, nil] Errors from resource if available
    def errors
      resource.respond_to?(:errors) ? resource.errors : nil
    end
  end
end
