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
        @performed = false
      end

      def log_debug(_message)
        # Mock method for testing
      end

      def log_exception(_exception, _context = {})
        # Mock method for testing
      end

      def respond_with_success(data, status: :ok, meta: {})
        @performed = true
        { success: true, data: data }
      end

      def respond_with_error(error, status: :unprocessable_entity, meta: {})
        @performed = true
        { success: false, error: error.is_a?(Exception) ? error.message : error }
      end

      def performed?
        @performed
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

    before do
      BetterController.reset_config!
    end

    after do
      BetterController.reset_config!
    end

    context 'when logging is enabled' do
      before do
        BetterController.config.error_handling_log_errors = true
      end

      it 'logs the exception and returns an error response' do
        expect(controller).to receive(:log_exception).with(exception, { controller: controller.class.name, action: 'test_action' })

        result = controller.send(:handle_exception, exception)
        expect(result).to eq({ success: false, error: 'Test error' })
      end
    end

    context 'when logging is disabled' do
      before do
        BetterController.config.error_handling_log_errors = false
      end

      it 'returns an error response without logging' do
        expect(controller).not_to receive(:log_exception)

        result = controller.send(:handle_exception, exception)
        expect(result).to eq({ success: false, error: 'Test error' })
      end
    end
  end

  describe '#handle_service_error' do
    # Create a mock resource with errors
    let(:mock_resource) do
      obj = Object.new
      errors = { base: ['Name is required', 'Email is invalid'] }
      obj.define_singleton_method(:errors) do
        OpenStruct.new(to_hash: errors)
      end
      obj
    end

    let(:service_error) do
      BetterController::Errors::ServiceError.new(
        mock_resource,
        { message: 'Service validation failed', status: :bad_request }
      )
    end

    let(:controller_with_log_error) do
      Class.new do
        include BetterController::Controllers::Base

        attr_accessor :action_name, :logged_messages

        def initialize
          @action_name = 'test_action'
          @performed = false
          @logged_messages = []
        end

        def log_error(message, _meta = {})
          @logged_messages << { message: message }
        end

        def respond_with_error(error, status: :unprocessable_entity, meta: {})
          @performed = true
          { success: false, error: error, status: status, meta: meta }
        end

        def performed?
          @performed
        end
      end.new
    end

    before do
      BetterController.reset_config!
    end

    after do
      BetterController.reset_config!
    end

    context 'when logging is enabled' do
      before do
        BetterController.config.error_handling_log_errors = true
      end

      it 'logs the service error' do
        controller_with_log_error.send(:handle_service_error, service_error)

        expect(controller_with_log_error.logged_messages.size).to eq(1)
        expect(controller_with_log_error.logged_messages.first[:message]).to include('Service validation failed')
      end

      it 'returns error response with service error details' do
        result = controller_with_log_error.send(:handle_service_error, service_error)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Service validation failed')
        expect(result[:status]).to eq(:bad_request)
        expect(result[:meta][:errors]).to eq({ base: ['Name is required', 'Email is invalid'] })
      end
    end

    context 'when logging is disabled' do
      before do
        BetterController.config.error_handling_log_errors = false
      end

      it 'does not log the service error' do
        controller_with_log_error.send(:handle_service_error, service_error)

        expect(controller_with_log_error.logged_messages).to be_empty
      end

      it 'still returns error response' do
        result = controller_with_log_error.send(:handle_service_error, service_error)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Service validation failed')
      end
    end

    context 'with default status' do
      it 'uses unprocessable_entity when no status in meta' do
        error_without_status = BetterController::Errors::ServiceError.new(nil, { message: 'Error' })
        result = controller_with_log_error.send(:handle_service_error, error_without_status)

        expect(result[:status]).to eq(:unprocessable_entity)
      end
    end
  end
end
