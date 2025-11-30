# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# Unit tests (no Rails required)
RSpec::Core::RakeTask.new(:spec_unit) do |t|
  t.pattern = 'spec/better_controller/**/*_spec.rb,spec/better_controller_spec.rb'
end

# Integration tests (requires Rails)
RSpec::Core::RakeTask.new(:spec_integration) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end

# Generator tests (requires Rails)
RSpec::Core::RakeTask.new(:spec_generators) do |t|
  t.pattern = 'spec/generators/**/*_spec.rb'
end

# Run integration/generator tests first (they load real Rails),
# then unit tests (which use fake Rails module).
# This avoids conflicts when running all tests together.
desc 'Run all specs (integration first, then unit)'
task spec: %i[spec_integration spec_generators spec_unit]

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]
