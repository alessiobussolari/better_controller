# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Controllers::Base do
  # Create a test controller class that includes the Base module
  let(:test_controller_class) do
    Class.new do
      include BetterController::Controllers::Base
      
      attr_accessor :action_name
      
      def initialize
        @action_name = 'test_action'
      end
      
      def log_debug(message)
        # Mock method for testing
      end
      
      def log_exception(exception, context = {})
        # Mock method for testing
      end
      
      def respond_with_success(data, options = {})
        { success: true, data: data }
      end
      
      def respond_with_error(error, options = {})
        { success: false, error: error.is_a?(Exception) ? error.message : error }
      end
    end
  end
  
  let(:controller) { test_controller_class.new }
  
  describe '#execute_action' do
    context 'when the action succeeds' do
      it 'executes the block and returns a success response' do
        result = controller.execute_action do
          'test result'
        end
        
        expect(result).to eq({ success: true, data: 'test result' })
      end
    end
    
    context 'when the action raises an error' do
      it 'handles the exception and returns an error response' do
        result = controller.execute_action do
          raise StandardError, 'Test error'
        end
        
        expect(result).to eq({ success: false, error: 'Test error' })
      end
    end
  end
  
  describe '#with_transaction' do
    # Create a mock implementation of ActiveRecord::Base with a transaction method
    before do
      module ActiveRecord
        class Base
          def self.transaction
            yield if block_given?
          end
        end
      end
    end
    
    # Clean up our mock after tests
    after do
      Object.send(:remove_const, :ActiveRecord) if defined?(ActiveRecord)
    end
    
    context 'when the transaction succeeds' do
      it 'executes the block within a transaction' do
        result = nil
        
        expect do
          result = controller.with_transaction do
            'transaction result'
          end
        end.not_to raise_error
        
        expect(result).to eq('transaction result')
      end
    end
    
    context 'when the transaction raises an error' do
      it 'handles the exception' do
        expect(controller).to receive(:handle_exception).with(instance_of(StandardError), {})
        
        controller.with_transaction do
          raise StandardError, 'Transaction error'
        end
      end
    end
  end
  
  describe '#better_controller_handle_error' do
    it 'delegates to handle_exception' do
      exception = StandardError.new('Test error')
      expect(controller).to receive(:handle_exception).with(exception)
      
      controller.better_controller_handle_error(exception)
    end
  end
  
  describe '#handle_exception' do
    let(:exception) { StandardError.new('Test error') }
    
    context 'when logging is enabled' do
      before do
        allow(BetterController.config.error_handling).to receive(:[]).with(:log_errors).and_return(true)
      end
      
      it 'logs the exception and returns an error response' do
        expect(controller).to receive(:log_exception).with(exception, { controller: controller.class.name, action: 'test_action' })
        
        result = controller.send(:handle_exception, exception)
        expect(result).to eq({ success: false, error: 'Test error' })
      end
    end
    
    context 'when logging is disabled' do
      before do
        allow(BetterController.config.error_handling).to receive(:[]).with(:log_errors).and_return(false)
      end
      
      it 'returns an error response without logging' do
        expect(controller).not_to receive(:log_exception)
        
        result = controller.send(:handle_exception, exception)
        expect(result).to eq({ success: false, error: 'Test error' })
      end
    end
  end
end
