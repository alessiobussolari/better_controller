# frozen_string_literal: true

require 'spec_helper'
require 'better_controller_api'

RSpec.describe BetterController do
  it "has a version number" do
    expect(BetterController::VERSION).not_to be nil
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
      expect(controller).to respond_to(:respond_with_pagination)
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
