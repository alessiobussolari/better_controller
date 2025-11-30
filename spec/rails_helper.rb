# frozen_string_literal: true

# This file is loaded for tests that require a full Rails environment
# Set INTEGRATION_TESTS BEFORE anything else to signal spec_helper
ENV['RAILS_ENV'] ||= 'test'
ENV['INTEGRATION_TESTS'] = 'true'

# Load the Rails test application
require_relative 'rails_app/config/environment'

require 'rspec/rails'

# SimpleCov after Rails is loaded
require 'simplecov'
require 'simplecov_json_formatter'

# Configure SimpleCov for integration tests
SimpleCov.command_name 'integration'

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

  add_group 'Controllers', 'lib/better_controller/controllers'
  add_group 'Utils', 'lib/better_controller/utils'
  add_group 'DSL', 'lib/better_controller/dsl'
  add_group 'Rendering', 'lib/better_controller/rendering'
  add_group 'Generators', 'lib/generators/'

  track_files '{lib}/**/*.rb'

  add_filter 'spec/'
  add_filter 'lib/better_controller.rb'
  add_filter 'lib/better_controller/railtie.rb'
  add_filter 'lib/better_controller/version.rb'
  add_filter 'lib/better_controller_api.rb'
  add_filter %r{lib/generators/}
end

# Run migrations in memory
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.define do
  create_table :examples, force: true do |t|
    t.string :name
    t.string :email
    t.timestamps
  end

  create_table :articles, force: true do |t|
    t.string :title
    t.text :body
    t.boolean :published, default: false
    t.timestamps
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.filter_run_when_matching(:focus)

  config.silence_filter_announcements = true
  config.fail_if_no_examples = true
  config.warnings = false

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand(config.seed)
end
