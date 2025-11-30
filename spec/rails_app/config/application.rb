# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)
require 'better_controller'

module RailsApp
  class Application < Rails::Application
    # Set the root to the rails_app directory
    config.root = File.expand_path('..', __dir__)

    config.load_defaults 7.1
    config.eager_load = false
    # config.api_only = true  # Disabled to support Turbo Stream helpers

    # Don't generate system test files
    config.generators.system_tests = nil
  end
end
