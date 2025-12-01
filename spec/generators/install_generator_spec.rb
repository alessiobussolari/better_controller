# frozen_string_literal: true

require 'rails_helper'
require 'generator_spec'
require 'generators/better_controller/install_generator'
require 'support/shared_examples/generators'

RSpec.describe BetterController::Generators::InstallGenerator, type: :generator do
  destination File.expand_path('../tmp', __dir__)

  before do
    prepare_destination
    # Create config directory for routes
    FileUtils.mkdir_p(File.join(destination_root, 'config'))
    File.write(File.join(destination_root, 'config/routes.rb'), "Rails.application.routes.draw do\nend")
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  describe 'generator class' do
    it 'inherits from Rails::Generators::Base' do
      expect(described_class.superclass).to eq(Rails::Generators::Base)
    end

    it 'defines source_root' do
      expect(described_class).to respond_to(:source_root)
    end

    it 'source_root points to templates directory' do
      expect(described_class.source_root).to include('templates')
    end

    it 'templates directory exists' do
      expect(Dir.exist?(described_class.source_root)).to be true
    end
  end

  describe 'generator execution' do
    before { run_generator }

    it 'creates initializer file' do
      assert_file 'config/initializers/better_controller.rb'
    end

    it 'initializer contains configuration block' do
      assert_file 'config/initializers/better_controller.rb' do |content|
        expect(content).to include('BetterController.configure')
      end
    end

    it 'adds route comment to routes file' do
      assert_file 'config/routes.rb' do |content|
        expect(content).to include('BetterController routes')
      end
    end
  end

  describe '#create_initializer' do
    it 'creates initializer using template method' do
      generator = described_class.new
      generator.destination_root = destination_root
      FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))

      generator.create_initializer

      expect(File.exist?(File.join(destination_root, 'config/initializers/better_controller.rb'))).to be true
    end
  end

  describe '#mount_routes' do
    it 'adds route comment' do
      generator = described_class.new
      generator.destination_root = destination_root

      # Allow route injection
      allow(generator).to receive(:route)

      generator.mount_routes

      expect(generator).to have_received(:route).with('# BetterController routes can be added here')
    end
  end

  describe '#show_readme' do
    it 'displays readme when invoking' do
      generator = described_class.new
      generator.destination_root = destination_root
      allow(generator).to receive(:behavior).and_return(:invoke)
      allow(generator).to receive(:readme)

      generator.show_readme

      expect(generator).to have_received(:readme).with('README')
    end

    it 'does not display readme when revoking' do
      generator = described_class.new
      generator.destination_root = destination_root
      allow(generator).to receive(:behavior).and_return(:revoke)
      allow(generator).to receive(:readme)

      generator.show_readme

      expect(generator).not_to have_received(:readme)
    end
  end

  describe 'idempotency' do
    it 'can be run multiple times without error' do
      expect { run_generator }.not_to raise_error
      expect { run_generator }.not_to raise_error
    end

    it 'overwrites initializer on second run' do
      run_generator
      first_content = File.read(File.join(destination_root, 'config/initializers/better_controller.rb'))

      run_generator
      second_content = File.read(File.join(destination_root, 'config/initializers/better_controller.rb'))

      expect(first_content).to eq(second_content)
    end
  end

  describe 'initializer content' do
    before { run_generator }

    it 'includes frozen_string_literal comment' do
      assert_file 'config/initializers/better_controller.rb' do |content|
        expect(content).to start_with('# frozen_string_literal: true')
      end
    end

    it 'generates syntactically valid Ruby' do
      file_path = File.join(destination_root, 'config/initializers/better_controller.rb')
      expect { RubyVM::InstructionSequence.compile_file(file_path) }.not_to raise_error
    end

    it 'includes pagination_per_page configuration' do
      assert_file 'config/initializers/better_controller.rb' do |content|
        expect(content).to include('pagination_per_page')
      end
    end

    it 'includes pagination_enabled configuration' do
      assert_file 'config/initializers/better_controller.rb' do |content|
        expect(content).to include('pagination_enabled')
      end
    end

    it 'includes turbo_enabled configuration' do
      assert_file 'config/initializers/better_controller.rb' do |content|
        expect(content).to include('turbo_enabled')
      end
    end

    it 'includes html_page_component_namespace configuration' do
      assert_file 'config/initializers/better_controller.rb' do |content|
        expect(content).to include('html_page_component_namespace')
      end
    end
  end

  describe 'README template' do
    it 'has README template file' do
      readme_path = File.join(described_class.source_root, 'README')
      expect(File.exist?(readme_path)).to be true
    end

    it 'README contains usage instructions' do
      readme_path = File.join(described_class.source_root, 'README')
      content = File.read(readme_path)
      expect(content.length).to be > 0
    end
  end

  describe 'with existing initializer' do
    before do
      FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
      File.write(
        File.join(destination_root, 'config/initializers/better_controller.rb'),
        "# Custom configuration\nBetterController.configure { |c| c.api_version = 'v2' }"
      )
    end

    it 'overwrites existing initializer' do
      run_generator

      assert_file 'config/initializers/better_controller.rb' do |content|
        # New template has pagination_per_page instead of api_version
        expect(content).to include('pagination_per_page')
      end
    end
  end

  describe 'with missing config directory' do
    before do
      FileUtils.rm_rf(File.join(destination_root, 'config/initializers'))
    end

    it 'creates config/initializers directory' do
      run_generator

      expect(Dir.exist?(File.join(destination_root, 'config/initializers'))).to be true
    end
  end
end
