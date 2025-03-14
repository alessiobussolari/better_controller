# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController do
  it "has a version number" do
    expect(BetterController::VERSION).not_to be nil
  end

  describe "when included in a controller" do
    # Create a test controller class that includes BetterController
    class TestBaseController
      def self.before_action(*args); end
      def self.include(mod); end
      def self.class_attribute(*args, **kwargs); end
      
      # Manually include the modules that BetterController would include
      include BetterController::Base
      include BetterController::ResponseHelpers
      include BetterController::ParameterValidation
      
      def params
        {}
      end
      
      def logger
        @logger ||= double('logger').tap do |logger|
          allow(logger).to receive(:error)
        end
      end
    end
    
    let(:controller) { TestBaseController.new }
    
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
  end
end
