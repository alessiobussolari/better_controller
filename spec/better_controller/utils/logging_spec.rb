# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'stringio'

RSpec.describe BetterController::Utils::Logging do
  let(:log_output) { StringIO.new }
  let(:test_logger) { Logger.new(log_output) }

  let(:controller_class) do
    Class.new do
      include BetterController::Utils::Logging

      attr_accessor :action_name

      def initialize
        @action_name = 'test_action'
      end

      def self.name
        'TestController'
      end
    end
  end

  let(:controller) { controller_class.new }

  before do
    controller_class.better_controller_logger = test_logger
  end

  describe '#log_info' do
    it 'logs at info level' do
      controller.log_info('Test message')

      log_output.rewind
      output = log_output.read

      expect(output).to include('INFO')
      expect(output).to include('Test message')
    end

    it 'includes tags in log message' do
      controller.log_info('Test message', user_id: 123)

      log_output.rewind
      output = log_output.read

      expect(output).to include('user_id')
      expect(output).to include('123')
    end

    it 'includes controller name in tags' do
      controller.log_info('Test message')

      log_output.rewind
      output = log_output.read

      expect(output).to include('TestController')
    end

    it 'includes action name in tags' do
      controller.log_info('Test message')

      log_output.rewind
      output = log_output.read

      expect(output).to include('test_action')
    end
  end

  describe '#log_debug' do
    before do
      test_logger.level = Logger::DEBUG
    end

    it 'logs at debug level' do
      controller.log_debug('Debug message')

      log_output.rewind
      output = log_output.read

      expect(output).to include('DEBUG')
      expect(output).to include('Debug message')
    end
  end

  describe '#log_warn' do
    it 'logs at warn level' do
      controller.log_warn('Warning message')

      log_output.rewind
      output = log_output.read

      expect(output).to include('WARN')
      expect(output).to include('Warning message')
    end
  end

  describe '#log_error' do
    it 'logs at error level' do
      controller.log_error('Error message')

      log_output.rewind
      output = log_output.read

      expect(output).to include('ERROR')
      expect(output).to include('Error message')
    end
  end

  describe '#log_fatal' do
    it 'logs at fatal level' do
      controller.log_fatal('Fatal message')

      log_output.rewind
      output = log_output.read

      expect(output).to include('FATAL')
      expect(output).to include('Fatal message')
    end
  end

  describe '#log_exception' do
    let(:exception) { StandardError.new('Test exception') }

    before do
      exception.set_backtrace(['line1', 'line2'])
      allow(BetterController.config).to receive(:error_handling).and_return({ log_errors: true })
    end

    it 'logs exception message at error level' do
      controller.log_exception(exception)

      log_output.rewind
      output = log_output.read

      expect(output).to include('ERROR')
      expect(output).to include('Test exception')
    end

    it 'includes exception class name' do
      controller.log_exception(exception)

      log_output.rewind
      output = log_output.read

      expect(output).to include('StandardError')
    end

    it 'includes backtrace' do
      controller.log_exception(exception)

      log_output.rewind
      output = log_output.read

      expect(output).to include('line1')
      expect(output).to include('line2')
    end

    it 'includes additional tags' do
      controller.log_exception(exception, request_id: 'abc123')

      log_output.rewind
      output = log_output.read

      expect(output).to include('request_id')
      expect(output).to include('abc123')
    end

    context 'when logging is disabled' do
      before do
        allow(BetterController.config).to receive(:error_handling).and_return({ log_errors: false })
      end

      it 'does not log anything' do
        controller.log_exception(exception)

        log_output.rewind
        output = log_output.read

        expect(output).to be_empty
      end
    end
  end

  describe '#logger' do
    it 'returns the class logger' do
      expect(controller.send(:logger)).to eq(test_logger)
    end
  end

  describe '.logger=' do
    it 'sets the class logger' do
      new_logger = Logger.new(StringIO.new)
      controller_class.logger = new_logger

      expect(controller_class.logger).to eq(new_logger)
    end
  end

  describe '.logger' do
    it 'returns the class logger' do
      expect(controller_class.logger).to eq(test_logger)
    end
  end

  context 'when logger is nil' do
    before do
      controller_class.better_controller_logger = nil
    end

    it 'does not raise error on log_info' do
      expect { controller.log_info('Test') }.not_to raise_error
    end

    it 'does not raise error on log_error' do
      expect { controller.log_error('Test') }.not_to raise_error
    end
  end

  context 'without action_name method' do
    let(:simple_class) do
      Class.new do
        include BetterController::Utils::Logging

        def self.name
          'SimpleClass'
        end
      end
    end

    it 'logs without action_name' do
      simple_class.better_controller_logger = test_logger
      instance = simple_class.new
      instance.log_info('Message', custom: 'tag')

      log_output.rewind
      output = log_output.read

      expect(output).to include('Message')
      expect(output).to include('custom')
    end
  end
end
