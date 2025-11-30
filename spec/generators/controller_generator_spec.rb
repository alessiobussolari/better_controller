# frozen_string_literal: true

require 'rails_helper'
require 'generator_spec'
require 'generators/better_controller/controller_generator'

RSpec.describe BetterController::Generators::ControllerGenerator, type: :generator do
  destination File.expand_path('../tmp', __dir__)

  before do
    prepare_destination
    FileUtils.mkdir_p(File.join(destination_root, 'app/controllers'))
  end

  after do
    FileUtils.rm_rf(destination_root)
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
end
