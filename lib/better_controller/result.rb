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

    # Hash-like access for compatibility with code that uses dig
    # @param keys [Array<Symbol>] Keys to dig into
    # @return [Object, nil] The value at the nested key path
    def dig(*keys)
      to_h.dig(*keys)
    end

    # Access value by key (hash-like interface)
    # @param key [Symbol] The key to access
    # @return [Object, nil] The value
    def [](key)
      to_h[key]
    end

    # Convert result to hash for compatibility
    # @return [Hash] Hash representation with resource, meta, and common keys
    def to_h
      {
        resource: resource,
        collection: resource.respond_to?(:each) && !resource.is_a?(Hash) ? resource : nil,
        meta: meta,
        success: success?,
        message: message,
        errors: errors,
        error: meta[:error],
        error_type: meta[:error_type],
        page_config: meta[:page_config]
      }.compact
    end
  end
end
