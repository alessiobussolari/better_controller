# frozen_string_literal: true

require 'zeitwerk'
require 'active_support'
require 'active_support/core_ext'

# Set up Zeitwerk autoloading
loader = Zeitwerk::Loader.for_gem
loader.setup

# Manually require core files
require_relative 'better_controller/version'
require_relative 'better_controller/method_not_overridden_error'
require_relative 'better_controller/configuration'
require_relative 'better_controller/logging'
require_relative 'better_controller/base'
require_relative 'better_controller/response_helpers'
require_relative 'better_controller/parameter_validation'
require_relative 'better_controller/action_helpers'
require_relative 'better_controller/service'
require_relative 'better_controller/serializer'
require_relative 'better_controller/pagination'
require_relative 'better_controller/params_helpers'
require_relative 'better_controller/resources_controller'

# Rails integration
require_relative 'better_controller/railtie' if defined?(Rails)

module BetterController
  class Error < StandardError; end

  # Configure BetterController
  # @yield [config] The configuration block
  def self.configure
    yield(Configuration) if block_given?
  end

  # Get the current configuration
  # @return [BetterController::Configuration] The current configuration
  def self.config
    Configuration
  end

  # Include BetterController modules in a controller
  # @param base [Class] The controller class
  def self.included(base)
    base.include(BetterController::Base)
    base.include(BetterController::ResponseHelpers)
    base.include(BetterController::ParameterValidation)
    base.include(BetterController::ParamsHelpers)
    base.include(BetterController::Logging)
    base.extend(BetterController::ActionHelpers::ClassMethods)
    base.extend(BetterController::Logging::ClassMethods)
  end
end
