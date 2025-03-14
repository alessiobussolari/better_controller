# frozen_string_literal: true

module BetterController
  module Utils
    # Error raised when a required method is not overridden
    class MethodNotOverriddenError < StandardError
    # Initialize a new error
    # @param method_name [Symbol, String] The method that should be overridden
    # @param instance [Object] The instance where the method should be overridden
    def initialize(method_name, instance)
      super("Method '#{method_name}' must be overridden in #{instance.class.name}")
    end
    end
  end
end
