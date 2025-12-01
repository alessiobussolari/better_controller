# frozen_string_literal: true

# This file is loaded for tests that require a full Rails environment
# IMPORTANT: SimpleCov MUST be started BEFORE loading Rails/gem code to track coverage

ENV['RAILS_ENV'] ||= 'test'
ENV['INTEGRATION_TESTS'] = 'true'

# SimpleCov FIRST - before any code is loaded
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

  # Coverage threshold - lower for integration tests since they focus on specific scenarios
  # Unit tests already enforce 95% coverage
  minimum_coverage 50
end

# AFTER SimpleCov - Load the Rails test application
require_relative 'rails_app/config/environment'

require 'rspec/rails'

# Run migrations in memory
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.define do
  create_table :examples, force: true do |t|
    t.string :name
    t.string :email
    t.text :description
    t.string :status, default: 'active'
    t.timestamps
  end

  create_table :articles, force: true do |t|
    t.string :title
    t.text :body
    t.boolean :published, default: false
    t.timestamps
  end

  create_table :users, force: true do |t|
    t.string :name
    t.string :email
    t.timestamps
  end

  create_table :comments, force: true do |t|
    t.references :article
    t.string :author
    t.text :body
    t.timestamps
  end

  create_table :tasks, force: true do |t|
    t.string :title
    t.text :description
    t.string :status, default: 'pending'
    t.integer :priority, default: 0
    t.timestamps
  end

  create_table :products, force: true do |t|
    t.string :name
    t.string :sku
    t.decimal :price, precision: 10, scale: 2
    t.string :category
    t.boolean :active, default: true
    t.integer :stock_quantity, default: 0
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
