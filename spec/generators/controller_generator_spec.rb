# frozen_string_literal: true

require 'rails_helper'
require 'generator_spec'
require 'generators/better_controller/controller_generator'
require 'support/shared_examples/generators'

RSpec.describe BetterController::Generators::ControllerGenerator, type: :generator do
  destination File.expand_path('../tmp', __dir__)

  before do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, 'app/controllers'))
  end

  after do
    FileUtils.rm_rf(destination_root)
  end

  it_behaves_like 'a Rails generator'

  describe 'source_root configuration' do
    it 'points to templates directory' do
      expect(described_class.source_root).to include('templates')
    end

    it 'templates directory exists' do
      expect(Dir.exist?(described_class.source_root)).to be true
    end
  end

  describe 'class options' do
    it 'has model option' do
      expect(described_class.class_options.keys).to include(:model)
    end

    it 'model option has correct description' do
      model_option = described_class.class_options[:model]
      expect(model_option.description.to_s.length).to be > 0
    end
  end

  describe 'with default options' do
    before { run_generator %w[users] }

    it 'creates controller file' do
      assert_file 'app/controllers/users_controller.rb'
    end

    it 'controller includes ResourcesController' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('UsersController')
        expect(content).to include('include BetterController::Controllers::ResourcesController')
      end
    end

    it 'controller defines resource_class method' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('def resource_class')
        expect(content).to include('User')
      end
    end

    it 'controller defines resource_params method' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('def resource_params')
        expect(content).to include('params.require(:user)')
      end
    end

    it 'does NOT create service file' do
      assert_no_file 'app/services/user_service.rb'
    end

    it 'does NOT create serializer file' do
      assert_no_file 'app/serializers/user_serializer.rb'
    end
  end

  describe 'with --model option' do
    before { run_generator %w[users --model=person] }

    it 'creates controller file' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('UsersController')
      end
    end

    it 'uses custom model name in resource_class' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('Person')
      end
    end

    it 'uses custom model name in resource_params' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('params.require(:person)')
      end
    end
  end

  describe 'with specific actions' do
    before { run_generator %w[products index show] }

    it 'creates controller file' do
      assert_file 'app/controllers/products_controller.rb'
    end

    it 'includes comments for specified actions' do
      assert_file 'app/controllers/products_controller.rb' do |content|
        expect(content).to include('# GET /products')
        expect(content).to include('# GET /products/:id')
      end
    end
  end

  describe 'pluralized controller name' do
    before { run_generator %w[posts] }

    it 'uses singular model name in resource_class' do
      assert_file 'app/controllers/posts_controller.rb' do |content|
        expect(content).to include('Post')
      end
    end

    it 'uses singular model name in resource_params' do
      assert_file 'app/controllers/posts_controller.rb' do |content|
        expect(content).to include('params.require(:post)')
      end
    end
  end

  describe 'private helper methods' do
    let(:generator) { described_class.new(['articles', 'index', 'show']) }

    it '#model_name returns singular file name when no model option' do
      expect(generator.send(:model_name)).to eq('article')
    end

    it '#model_class_name returns camelized model name' do
      expect(generator.send(:model_class_name)).to eq('Article')
    end

    it '#controller_actions returns symbolized actions' do
      expect(generator.send(:controller_actions)).to eq(%i[index show])
    end

    it '#has_action? returns true for specified actions' do
      expect(generator.send(:has_action?, :index)).to be true
      expect(generator.send(:has_action?, :show)).to be true
    end

    it '#has_action? returns false for unspecified actions' do
      expect(generator.send(:has_action?, :create)).to be false
    end
  end

  describe 'private helper methods with empty actions' do
    let(:generator) { described_class.new(['comments']) }

    it '#controller_actions returns empty array' do
      expect(generator.send(:controller_actions)).to eq([])
    end

    it '#has_action? returns true when no actions specified (all actions available)' do
      expect(generator.send(:has_action?, :index)).to be true
      expect(generator.send(:has_action?, :create)).to be true
    end
  end

  describe 'with namespaced controller' do
    before { run_generator %w[admin/users] }

    it 'creates controller in namespaced directory' do
      assert_file 'app/controllers/admin/users_controller.rb'
    end

    it 'defines namespaced controller class' do
      assert_file 'app/controllers/admin/users_controller.rb' do |content|
        expect(content).to include('class Admin::UsersController')
      end
    end
  end

  describe 'with deeply nested namespace' do
    before { run_generator %w[api/v1/admin/users] }

    it 'creates controller in deeply nested directory' do
      assert_file 'app/controllers/api/v1/admin/users_controller.rb'
    end

    it 'defines deeply namespaced controller class' do
      assert_file 'app/controllers/api/v1/admin/users_controller.rb' do |content|
        expect(content).to include('class Api::V1::Admin::UsersController')
      end
    end
  end

  describe 'idempotency' do
    it 'can be run multiple times without error' do
      expect { run_generator %w[users] }.not_to raise_error
      expect { run_generator %w[users] }.not_to raise_error
    end

    it 'overwrites existing file on second run' do
      run_generator %w[users]
      first_content = File.read(File.join(destination_root, 'app/controllers/users_controller.rb'))

      run_generator %w[users]
      second_content = File.read(File.join(destination_root, 'app/controllers/users_controller.rb'))

      expect(first_content).to eq(second_content)
    end
  end

  describe 'generated code quality' do
    before { run_generator %w[users] }

    it 'generates frozen_string_literal comment' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to start_with('# frozen_string_literal: true')
      end
    end

    it 'generates syntactically valid Ruby' do
      file_path = File.join(destination_root, 'app/controllers/users_controller.rb')
      expect { RubyVM::InstructionSequence.compile_file(file_path) }.not_to raise_error
    end

    it 'generates properly indented code' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        # Check for consistent 2-space indentation
        expect(content).not_to match(/\t/) # No tabs
        expect(content).to match(/^  def resource_class/) # 2-space indent for methods
        expect(content).to match(/^    /) # 4-space indent for method body
      end
    end
  end

  describe 'with special model names' do
    it 'handles pluralized controller name with singular model' do
      run_generator %w[people --model=person]
      assert_file 'app/controllers/people_controller.rb' do |content|
        expect(content).to include('Person')
        expect(content).to include('params.require(:person)')
      end
    end

    it 'handles irregular pluralization' do
      run_generator %w[analyses]
      assert_file 'app/controllers/analyses_controller.rb' do |content|
        expect(content).to include('Analysis')
      end
    end

    it 'handles camelcase names' do
      run_generator %w[user_profiles]
      assert_file 'app/controllers/user_profiles_controller.rb' do |content|
        expect(content).to include('UserProfile')
      end
    end
  end

  describe 'template content' do
    before { run_generator %w[users] }

    it 'includes private visibility marker' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('private')
      end
    end

    it 'includes class end marker' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content.strip).to end_with('end')
      end
    end
  end

  describe 'with all CRUD actions' do
    before { run_generator %w[users index show new create edit update destroy] }

    it 'includes comments for all CRUD actions' do
      assert_file 'app/controllers/users_controller.rb' do |content|
        expect(content).to include('# GET /users')
        expect(content).to include('# GET /users/:id')
        expect(content).to include('# GET /users/new')
        expect(content).to include('# POST /users')
        expect(content).to include('# GET /users/:id/edit')
        expect(content).to include('# PATCH/PUT /users/:id')
        expect(content).to include('# DELETE /users/:id')
      end
    end
  end
end
