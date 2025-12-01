# frozen_string_literal: true

# Check if we're running integration/generator tests - these require real Rails
# This is detected by ENV variable set by rails_helper
RUNNING_INTEGRATION_TESTS = ENV['INTEGRATION_TESTS'] == 'true'

require 'simplecov'
require 'simplecov_json_formatter'

# Use command name to allow merging results from different test runs
SimpleCov.command_name RUNNING_INTEGRATION_TESTS ? 'integration' : 'unit'

FORMATTERS = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
].freeze

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(FORMATTERS)
SimpleCov.start do
  enable_coverage :branch
  load_profile 'test_frameworks'

  add_filter %r{^/config/}
  add_filter %r{^/db/}
  add_filter 'spec/'
  # Exclude generator templates (ERB files, not executable Ruby)
  add_filter 'lib/generators/better_controller/templates/'
  # Exclude version file (only defines VERSION constant)
  add_filter 'lib/better_controller/version.rb'

  add_group 'Controllers', 'lib/better_controller/controllers'
  add_group 'Utils', 'lib/better_controller/utils'
  add_group 'DSL', 'lib/better_controller/dsl'
  add_group 'Rendering', 'lib/better_controller/rendering'
  add_group 'Errors', 'lib/better_controller/errors'
  add_group 'Generators', 'lib/generators/better_controller'
  add_group 'Core', %w[lib/better_controller.rb lib/better_controller_api.rb lib/better_controller/railtie.rb]

  track_files '{lib}/**/*.rb'

  # Coverage threshold
  minimum_coverage 95
end

# Set up fake Rails only if not running integration tests and Rails isn't already defined
unless RUNNING_INTEGRATION_TESTS
  # Load required libraries
  require 'pathname'
  require 'logger'

  # Define Rails constant if not already defined
  unless defined?(Rails)
    module Rails
      class Railtie
        def self.initializer(*args); end
        def self.initializers; []; end
        def self.rake_tasks; end
        def self.on_load(*args); end
      end

      def self.env
        'test'
      end

      def self.root
        Pathname.new(File.expand_path('../', __dir__))
      end

      def self.logger
        @logger ||= Logger.new($stdout).tap { |l| l.level = Logger::INFO }
      end

      def self.on_load(name, &block)
        # Only yield for action_controller, skip other on_load blocks
        return unless name == :action_controller && block_given?

        yield if defined?(ActionController)
      end

      # Add this method to ActiveSupport to avoid errors
      module ActiveSupport
        def self.on_load(name, &block)
          # Only yield for action_controller, skip other on_load blocks
          return unless name == :action_controller && block_given?

          yield if defined?(ActionController)
        end
      end
    end
  end

  # Load required gems for unit tests
  require 'active_support/all'
  require 'active_model'
  require 'action_controller'
end

# Always load the gem under test
# Note: We need to always require this even if BetterController is defined because
# the gemspec's require_relative 'lib/better_controller/version' only defines the
# BetterController module with VERSION, not the full gem.
require 'better_controller'

# Load support files for unit tests (integration tests load them via rails_helper)
unless RUNNING_INTEGRATION_TESTS
  Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].sort.each { |f| require f }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = 1_000_000
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  # Reset BetterController configuration after each test to prevent leaking state
  config.after(:each) do
    BetterController.reset_config! if defined?(BetterController) && BetterController.respond_to?(:reset_config!)
  end

  config.raise_errors_for_deprecations!
  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.filter_run_when_matching(:focus)

  config.silence_filter_announcements = true
  config.fail_if_no_examples = true
  config.warnings = false
  config.raise_on_warning = true unless RUNNING_INTEGRATION_TESTS
  config.threadsafe = true

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand(config.seed)
end
