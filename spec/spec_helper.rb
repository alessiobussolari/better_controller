# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

FORMATTERS = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter
].freeze

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(FORMATTERS)
SimpleCov.start do
  load_profile 'test_frameworks'

  add_filter %r{^/config/}
  add_filter %r{^/db/}

  add_group 'Serializer', 'lib/better_controller/serializer'
  add_group 'Controllers', 'lib/better_controller/resources_controller'
  add_group 'Services', 'lib/better_controller/service'
  add_group 'Pagination', 'lib/better_controller/pagination'
  add_group 'Helpers', 'lib/better_controller/params_helpers'

  track_files '{lib}/**/*.rb'

  add_filter 'spec/'
  add_filter 'lib/better_controller.rb'
  add_filter 'lib/better_controller/railtie.rb'
  add_filter 'lib/better_controller/version.rb'
end

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
      @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
    end
  end
end

# Define Rails constant to handle Railtie
module Rails
  def self.on_load(name, &block)
    # Only yield for action_controller, skip other on_load blocks
    if name == :action_controller && block_given?
      yield if defined?(ActionController)
    end
  end
  
  # Add this method to ActiveSupport to avoid errors
  module ActiveSupport
    def self.on_load(name, &block)
      # Only yield for action_controller, skip other on_load blocks
      if name == :action_controller && block_given?
        yield if defined?(ActionController)
      end
    end
  end
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

  config.raise_errors_for_deprecations!
  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.filter_run_when_matching(:focus)

  config.silence_filter_announcements = true
  config.fail_if_no_examples = true
  config.warnings = false
  config.raise_on_warning = true
  config.threadsafe = true

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand(config.seed)
end

# Load required gems first
require 'active_support/all'
require 'active_model'
require 'action_controller'

# Load the gem under test
require 'better_controller'

# Create a support directory and load all files in it
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].sort.each { |f| require f }
