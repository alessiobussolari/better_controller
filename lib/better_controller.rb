# frozen_string_literal: true

require 'zeitwerk'
require 'active_support'
require 'active_support/core_ext'

# Set up Zeitwerk autoloading
loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.ignore("#{__dir__}/better_controller_api.rb")
loader.ignore("#{__dir__}/generators")
loader.setup

# Require version and configuration first
require_relative 'better_controller/version'
require_relative 'better_controller/configuration'

# Require index files from each subdirectory
require_relative 'better_controller/utils/index'
require_relative 'better_controller/dsl/index'
require_relative 'better_controller/rendering/index'
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

  # Include BetterController HtmlController in a controller
  # This is a shortcut for: include BetterController::Controllers::HtmlController
  # Use this for HTML controllers with Turbo/ViewComponent support
  # @param base [Class] The controller class
  def self.included(base)
    base.include(BetterController::Controllers::HtmlController)
  end
end
