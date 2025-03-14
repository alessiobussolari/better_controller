# frozen_string_literal: true

require 'zeitwerk'
require 'active_support'
require 'active_support/core_ext'

# Set up Zeitwerk autoloading
loader = Zeitwerk::Loader.for_gem
loader.setup

# Require version and configuration first
require_relative 'better_controller/version'
require_relative 'better_controller/configuration'

# Require index files from each subdirectory
require_relative 'better_controller/utils/index'
require_relative 'better_controller/controllers/index'
require_relative 'better_controller/services/index'
require_relative 'better_controller/serializers/index'

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
    base.include(BetterController::Controllers::Base)
    base.include(BetterController::Controllers::ResponseHelpers)
    base.include(BetterController::Utils::ParameterValidation)
    base.include(BetterController::Utils::ParamsHelpers)
    base.include(BetterController::Utils::Logging)
    base.extend(BetterController::Controllers::ActionHelpers::ClassMethods)
    base.extend(BetterController::Utils::Logging::ClassMethods)
  end
end
