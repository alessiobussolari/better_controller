# frozen_string_literal: true

require 'spec_helper'
require 'better_controller_api'

RSpec.describe BetterController do
  describe 'VERSION constant' do
    it 'has a version number' do
      expect(BetterController::VERSION).not_to be_nil
    end

    it 'follows semantic versioning format' do
      expect(BetterController::VERSION).to match(/^\d+\.\d+\.\d+/)
    end

    it 'is a frozen string' do
      expect(BetterController::VERSION).to be_frozen
    end
  end

  describe '.configure' do
    it 'yields the configuration block' do
      yielded_config = nil
      BetterController.configure { |c| yielded_config = c }
      expect(yielded_config).to be_a(BetterController::Configuration)
    end

    it 'returns nil when no block given' do
      expect(BetterController.configure).to be_nil
    end

    it 'allows setting configuration values' do
      BetterController.configure do |config|
        config.api_version = 'v2'
      end
      expect(BetterController.config.api_version).to eq('v2')
    end
  end

  describe '.config' do
    it 'returns a Configuration instance' do
      expect(BetterController.config).to be_a(BetterController::Configuration)
    end

    it 'returns the same instance across calls' do
      config1 = BetterController.config
      config2 = BetterController.config
      expect(config1).to be(config2)
    end
  end

  describe '.configuration' do
    it 'is an alias for .config' do
      expect(BetterController.configuration).to eq(BetterController.config)
    end
  end

  describe 'module loading' do
    it 'loads all controller modules' do
      expect(defined?(BetterController::Controllers::Base)).to eq('constant')
      expect(defined?(BetterController::Controllers::HtmlController)).to eq('constant')
      expect(defined?(BetterController::Controllers::ResourcesController)).to eq('constant')
      expect(defined?(BetterController::Controllers::ResponseHelpers)).to eq('constant')
      expect(defined?(BetterController::Controllers::ActionHelpers)).to eq('constant')
    end

    it 'loads all DSL modules' do
      expect(defined?(BetterController::Dsl::ActionBuilder)).to eq('constant')
      expect(defined?(BetterController::Dsl::ResponseBuilder)).to eq('constant')
      expect(defined?(BetterController::Dsl::TurboStreamBuilder)).to eq('constant')
    end

    it 'loads all utility modules' do
      expect(defined?(BetterController::Utils::Pagination)).to eq('constant')
      expect(defined?(BetterController::Utils::ParamsHelpers)).to eq('constant')
      expect(defined?(BetterController::Utils::Logging)).to eq('constant')
      expect(defined?(BetterController::Utils::ParameterValidation)).to eq('constant')
    end

    it 'loads all rendering modules' do
      expect(defined?(BetterController::Rendering::ComponentRenderer)).to eq('constant')
      expect(defined?(BetterController::Rendering::PageConfigRenderer)).to eq('constant')
    end

    it 'loads all error classes' do
      expect(defined?(BetterController::Errors::ServiceError)).to eq('constant')
    end

    it 'loads configuration classes' do
      expect(defined?(BetterController::Configuration)).to eq('constant')
      expect(defined?(BetterController::Config)).to eq('constant')
      expect(defined?(BetterController::Result)).to eq('constant')
    end
  end

  describe "when included in a controller" do
    # Create a test controller class that includes BetterController
    class TestHtmlController
      def self.before_action(*args); end
      def self.class_attribute(*args, **kwargs); end
      def self.helper_method(*args); end

      # Include BetterController directly (now includes HtmlController)
      include BetterController

      def params
        {}
      end

      def request
        @request ||= double('request').tap do |req|
          allow(req).to receive(:headers).and_return({})
          allow(req).to receive(:format).and_return(double(turbo_stream?: false))
        end
      end
    end

    let(:controller) { TestHtmlController.new }

    it "includes the HtmlController module" do
      expect(controller).to respond_to(:page_config)
      expect(controller).to respond_to(:service_result)
      expect(controller).to respond_to(:resource)
      expect(controller).to respond_to(:collection)
    end

    it "includes the TurboSupport module" do
      expect(controller).to respond_to(:turbo_frame_request?)
      expect(controller).to respond_to(:turbo_stream_request?)
      expect(controller).to respond_to(:current_turbo_frame)
    end

    it "includes the ServiceResponder module" do
      expect(controller).to respond_to(:respond_with_service)
    end

    it "includes the ActionDsl class methods" do
      expect(TestHtmlController).to respond_to(:action)
    end
  end

  describe "BetterControllerApi when included in a controller" do
    # Create a test API controller class
    class TestApiController
      def self.before_action(*args); end
      def self.class_attribute(*args, **kwargs); end

      # Include BetterControllerApi for API controllers
      include BetterControllerApi

      def params
        {}
      end

      def logger
        @logger ||= double('logger').tap do |logger|
          allow(logger).to receive(:error)
        end
      end
    end

    let(:controller) { TestApiController.new }

    it "includes the Base module" do
      expect(controller).to respond_to(:execute_action)
      expect(controller).to respond_to(:with_transaction)
    end

    it "includes the ResponseHelpers module" do
      expect(controller).to respond_to(:respond_with_success)
      expect(controller).to respond_to(:respond_with_error)
    end

    it "includes the ParameterValidation module" do
      expect(controller).to respond_to(:validate_required_params)
      expect(controller).to respond_to(:validate_param_schema)
    end

    it "includes the Pagination module" do
      expect(controller).to respond_to(:paginate)
    end

    it "includes the Logging module" do
      expect(controller).to respond_to(:log_error)
    end
  end
end
