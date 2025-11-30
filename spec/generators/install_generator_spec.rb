# frozen_string_literal: true

require 'rails_helper'
require 'generator_spec'
require 'generators/better_controller/install_generator'

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
end
