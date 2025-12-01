# frozen_string_literal: true

require 'spec_helper'
require 'better_controller_api'

RSpec.describe BetterControllerApi do
  describe '.included' do
    let(:test_class) do
      Class.new do
        def self.before_action(*args); end
        def self.class_attribute(*args, **kwargs); end
        def self.helper_method(*args); end

        def params
          {}
        end

        def logger
          @logger ||= Logger.new(nil)
        end
      end
    end

    before { test_class.include(described_class) }

    describe 'module inclusions' do
      it 'includes Controllers::Base' do
        expect(test_class.included_modules).to include(BetterController::Controllers::Base)
      end

      it 'includes Controllers::ResponseHelpers' do
        expect(test_class.included_modules).to include(BetterController::Controllers::ResponseHelpers)
      end

      it 'includes Utils::ParameterValidation' do
        expect(test_class.included_modules).to include(BetterController::Utils::ParameterValidation)
      end

      it 'includes Utils::ParamsHelpers' do
        expect(test_class.included_modules).to include(BetterController::Utils::ParamsHelpers)
      end

      it 'includes Utils::Logging' do
        expect(test_class.included_modules).to include(BetterController::Utils::Logging)
      end

      it 'includes Utils::Pagination' do
        expect(test_class.included_modules).to include(BetterController::Utils::Pagination)
      end
    end

    describe 'class method extensions' do
      it 'extends ActionHelpers::ClassMethods' do
        expect(test_class).to respond_to(:requires_params)
        expect(test_class).to respond_to(:param_schema)
      end

      it 'extends Logging::ClassMethods' do
        expect(test_class).to respond_to(:logger)
        expect(test_class).to respond_to(:logger=)
      end
    end

    describe 'instance methods availability' do
      let(:instance) { test_class.new }

      it 'provides execute_action from Base' do
        expect(instance).to respond_to(:execute_action)
      end

      it 'provides with_transaction from Base' do
        expect(instance).to respond_to(:with_transaction)
      end

      it 'provides respond_with_success from ResponseHelpers' do
        expect(instance).to respond_to(:respond_with_success)
      end

      it 'provides respond_with_error from ResponseHelpers' do
        expect(instance).to respond_to(:respond_with_error)
      end

      it 'provides validate_required_params from ParameterValidation' do
        expect(instance).to respond_to(:validate_required_params)
      end

      it 'provides validate_param_schema from ParameterValidation' do
        expect(instance).to respond_to(:validate_param_schema)
      end

      it 'provides paginate from Pagination' do
        expect(instance).to respond_to(:paginate)
      end

      it 'provides pagination_meta from Pagination' do
        expect(instance).to respond_to(:pagination_meta)
      end

      it 'provides log_error from Logging' do
        expect(instance).to respond_to(:log_error)
      end

      it 'provides log_info from Logging' do
        expect(instance).to respond_to(:log_info)
      end

      it 'provides boolean_param from ParamsHelpers' do
        expect(instance).to respond_to(:boolean_param)
      end

      it 'provides integer_param from ParamsHelpers' do
        expect(instance).to respond_to(:integer_param)
      end

      it 'provides array_param from ParamsHelpers' do
        expect(instance).to respond_to(:array_param)
      end
    end
  end

  describe 'does NOT include HTML/Turbo modules' do
    let(:test_class) do
      Class.new do
        def self.before_action(*args); end
        def self.class_attribute(*args, **kwargs); end
        def self.helper_method(*args); end

        def params
          {}
        end

        def logger
          @logger ||= Logger.new(nil)
        end
      end
    end

    before { test_class.include(described_class) }

    it 'does not include TurboSupport' do
      expect(test_class.included_modules).not_to include(BetterController::Controllers::Concerns::TurboSupport)
    end

    it 'does not include ServiceResponder' do
      expect(test_class.included_modules).not_to include(BetterController::Controllers::Concerns::ServiceResponder)
    end

    it 'does not include ActionDsl' do
      expect(test_class.included_modules).not_to include(BetterController::Controllers::Concerns::ActionDsl)
    end

    it 'does not include CsvSupport' do
      expect(test_class.included_modules).not_to include(BetterController::Controllers::Concerns::CsvSupport)
    end
  end
end
