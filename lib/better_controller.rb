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
require_relative 'better_controller/result'
require_relative 'better_controller/config'
require_relative 'better_controller/errors/index'

# Require index files from each subdirectory
require_relative 'better_controller/utils/index'
require_relative 'better_controller/dsl/index'
require_relative 'better_controller/rendering/index'
require_relative 'better_controller/controllers/index'

# Rails integration
require_relative 'better_controller/railtie' if defined?(Rails)

module BetterController
  class Error < StandardError; end

  class << self
    # Get the current configuration (singleton instance)
    # @return [BetterController::Configuration] The current configuration
    def config
      @config ||= Configuration.new
    end

    # Configure BetterController (Kaminari-style)
    # @yield [config] The configuration block
    # @example
    #   BetterController.configure do |config|
    #     config.pagination_per_page = 25
    #     config.wrapped_responses_class = BetterController::Result
    #   end
    def configure
      yield(config) if block_given?
    end

    # Reset configuration to defaults (useful for testing)
    # @return [BetterController::Configuration] The new configuration
    def reset_config!
      @config = Configuration.new
    end

    # Alias for config (for backwards compatibility)
    alias configuration config

    # Include BetterController HtmlController in a controller
    # This is a shortcut for: include BetterController::Controllers::HtmlController
    # Use this for HTML controllers with Turbo/ViewComponent support
    # @param base [Class] The controller class
    def included(base)
      base.include(BetterController::Controllers::HtmlController)
    end
  end
end
