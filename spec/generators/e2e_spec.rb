# frozen_string_literal: true

require 'rails_helper'
require 'generator_spec'
require 'generators/better_controller/controller_generator'
require 'generators/better_controller/install_generator'

RSpec.describe 'Generator E2E Tests', type: :generator do
  destination File.expand_path('../tmp/e2e', __dir__)

  before do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, 'app/controllers'))
    FileUtils.mkdir_p(File.join(destination_root, 'config/initializers'))
    File.write(File.join(destination_root, 'config/routes.rb'), "Rails.application.routes.draw do\nend")
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  describe 'Full installation workflow' do
    it 'install then controller generation works correctly' do
      # Step 1: Run install generator
      generator = BetterController::Generators::InstallGenerator.new
      generator.destination_root = destination_root
      generator.invoke_all

      expect(File.exist?(File.join(destination_root, 'config/initializers/better_controller.rb'))).to be true

      # Step 2: Run controller generator
      controller_generator = BetterController::Generators::ControllerGenerator.new(['products'])
      controller_generator.destination_root = destination_root
      controller_generator.invoke_all

      expect(File.exist?(File.join(destination_root, 'app/controllers/products_controller.rb'))).to be true
    end

    it 'generated controller can be loaded' do
      # Generate controller
      generator = BetterController::Generators::ControllerGenerator.new(['widgets'])
      generator.destination_root = destination_root
      generator.invoke_all

      controller_path = File.join(destination_root, 'app/controllers/widgets_controller.rb')

      # Verify it compiles
      expect { RubyVM::InstructionSequence.compile_file(controller_path) }.not_to raise_error

      # Verify content structure
      content = File.read(controller_path)
      expect(content).to include('class WidgetsController')
      expect(content).to include('include BetterController::Controllers::ResourcesController')
      expect(content).to include('def resource_class')
      expect(content).to include('Widget')
      expect(content).to include('def resource_params')
      expect(content).to include('params.require(:widget)')
    end
  end

  describe 'Multiple controller generation' do
    it 'generates multiple controllers without conflicts' do
      %w[users posts comments].each do |name|
        generator = BetterController::Generators::ControllerGenerator.new([name])
        generator.destination_root = destination_root
        generator.invoke_all
      end

      expect(File.exist?(File.join(destination_root, 'app/controllers/users_controller.rb'))).to be true
      expect(File.exist?(File.join(destination_root, 'app/controllers/posts_controller.rb'))).to be true
      expect(File.exist?(File.join(destination_root, 'app/controllers/comments_controller.rb'))).to be true

      # Each controller should have correct model
      expect(File.read(File.join(destination_root, 'app/controllers/users_controller.rb'))).to include('User')
      expect(File.read(File.join(destination_root, 'app/controllers/posts_controller.rb'))).to include('Post')
      expect(File.read(File.join(destination_root, 'app/controllers/comments_controller.rb'))).to include('Comment')
    end
  end

  describe 'Namespaced controller generation' do
    it 'generates admin namespace controller' do
      FileUtils.mkdir_p(File.join(destination_root, 'app/controllers/admin'))

      generator = BetterController::Generators::ControllerGenerator.new(['admin/users'])
      generator.destination_root = destination_root
      generator.invoke_all

      controller_path = File.join(destination_root, 'app/controllers/admin/users_controller.rb')
      expect(File.exist?(controller_path)).to be true

      content = File.read(controller_path)
      expect(content).to include('class Admin::UsersController')
      expect(content).to include('User')
    end

    it 'generates API versioned namespace controller' do
      FileUtils.mkdir_p(File.join(destination_root, 'app/controllers/api/v1'))

      generator = BetterController::Generators::ControllerGenerator.new(['api/v1/users'])
      generator.destination_root = destination_root
      generator.invoke_all

      controller_path = File.join(destination_root, 'app/controllers/api/v1/users_controller.rb')
      expect(File.exist?(controller_path)).to be true

      content = File.read(controller_path)
      expect(content).to include('class Api::V1::UsersController')
    end
  end

  describe 'Controller with custom model' do
    it 'generates controller using custom model' do
      generator = BetterController::Generators::ControllerGenerator.new(['people', '--model=person'])
      generator.destination_root = destination_root
      generator.invoke_all

      controller_path = File.join(destination_root, 'app/controllers/people_controller.rb')
      content = File.read(controller_path)

      expect(content).to include('class PeopleController')
      expect(content).to include('Person')
      expect(content).to include('params.require(:person)')
    end
  end

  describe 'Controller with specific actions' do
    it 'generates controller with only specified actions' do
      generator = BetterController::Generators::ControllerGenerator.new(['articles', 'index', 'show'])
      generator.destination_root = destination_root
      generator.invoke_all

      controller_path = File.join(destination_root, 'app/controllers/articles_controller.rb')
      content = File.read(controller_path)

      expect(content).to include('# GET /articles')
      expect(content).to include('# GET /articles/:id')
    end
  end

  describe 'Generated initializer content' do
    it 'creates valid initializer configuration' do
      generator = BetterController::Generators::InstallGenerator.new
      generator.destination_root = destination_root
      generator.invoke_all

      initializer_path = File.join(destination_root, 'config/initializers/better_controller.rb')
      content = File.read(initializer_path)

      # Check configuration options
      expect(content).to include('BetterController.configure')
      expect(content).to include('pagination_enabled')
      expect(content).to include('pagination_per_page')
      expect(content).to include('turbo_enabled')
      expect(content).to include('html_page_component_namespace')

      # Verify syntax
      expect { RubyVM::InstructionSequence.compile_file(initializer_path) }.not_to raise_error
    end
  end

  describe 'Error handling' do
    it 'handles invalid controller names gracefully' do
      # Empty name should raise an error or handle gracefully
      expect do
        generator = BetterController::Generators::ControllerGenerator.new([])
        generator.destination_root = destination_root
        generator.invoke_all
      end.to raise_error(Thor::RequiredArgumentMissingError)
    end
  end

  describe 'Re-running generators (idempotency)' do
    it 'install generator is idempotent' do
      2.times do
        generator = BetterController::Generators::InstallGenerator.new
        generator.destination_root = destination_root
        expect { generator.invoke_all }.not_to raise_error
      end
    end

    it 'controller generator is idempotent' do
      2.times do
        generator = BetterController::Generators::ControllerGenerator.new(['orders'])
        generator.destination_root = destination_root
        expect { generator.invoke_all }.not_to raise_error
      end

      # File should exist with correct content
      controller_path = File.join(destination_root, 'app/controllers/orders_controller.rb')
      expect(File.exist?(controller_path)).to be true
    end
  end

  describe 'Generated files quality' do
    before do
      generator = BetterController::Generators::ControllerGenerator.new(['quality_test'])
      generator.destination_root = destination_root
      generator.invoke_all
    end

    let(:content) { File.read(File.join(destination_root, 'app/controllers/quality_test_controller.rb')) }

    it 'uses frozen_string_literal pragma' do
      expect(content).to start_with('# frozen_string_literal: true')
    end

    it 'has no trailing whitespace' do
      content.each_line do |line|
        expect(line.rstrip).to eq(line.chomp)
      end
    end

    it 'uses 2-space indentation consistently' do
      expect(content).not_to include("\t")
    end

    it 'ends with newline' do
      expect(content).to end_with("\n")
    end
  end
end
