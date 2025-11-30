# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Utils::ParameterValidation do
  let(:controller_class) do
    Class.new do
      include BetterController::Utils::ParameterValidation

      attr_accessor :params

      def initialize
        @params = {}
      end
    end
  end

  let(:controller) { controller_class.new }

  describe '#validate_required_params' do
    context 'when all required params are present' do
      it 'returns true' do
        controller.params = { name: 'Test', email: 'test@example.com' }

        expect(controller.validate_required_params(:name, :email)).to be true
      end

      it 'accepts string keys' do
        controller.params = { 'name' => 'Test' }

        expect(controller.validate_required_params(:name)).to be true
      end

      it 'accepts symbol keys' do
        controller.params = { name: 'Test' }

        expect(controller.validate_required_params(:name)).to be true
      end
    end

    context 'when required params are missing' do
      it 'raises BetterController::Error' do
        controller.params = { name: 'Test' }

        expect do
          controller.validate_required_params(:name, :email)
        end.to raise_error(BetterController::Error)
      end

      it 'includes missing param names in error message' do
        controller.params = {}

        expect do
          controller.validate_required_params(:name, :email)
        end.to raise_error(BetterController::Error, /name/)
      end

      it 'lists all missing params' do
        controller.params = {}

        expect do
          controller.validate_required_params(:name, :email, :age)
        end.to raise_error(BetterController::Error, /name.*email.*age/m)
      end
    end
  end

  describe '#validate_param_schema' do
    context 'with required validation' do
      it 'passes when required param is present' do
        controller.params = { name: 'Test' }
        schema = { name: { required: true } }

        expect(controller.validate_param_schema(schema)).to be true
      end

      it 'fails when required param is missing' do
        controller.params = {}
        schema = { name: { required: true } }

        expect do
          controller.validate_param_schema(schema)
        end.to raise_error(BetterController::Error, /name is required/)
      end
    end

    context 'with type validation' do
      it 'passes when type matches' do
        controller.params = { count: 5 }
        schema = { count: { type: Integer } }

        expect(controller.validate_param_schema(schema)).to be true
      end

      it 'fails when type does not match' do
        controller.params = { count: 'five' }
        schema = { count: { type: Integer } }

        expect do
          controller.validate_param_schema(schema)
        end.to raise_error(BetterController::Error, /count must be a Integer/)
      end

      it 'skips type check for nil values' do
        controller.params = { count: nil }
        schema = { count: { type: Integer } }

        expect(controller.validate_param_schema(schema)).to be true
      end
    end

    context 'with inclusion validation' do
      it 'passes when value is in allowed list' do
        controller.params = { status: 'active' }
        schema = { status: { in: %w[active inactive pending] } }

        expect(controller.validate_param_schema(schema)).to be true
      end

      it 'fails when value is not in allowed list' do
        controller.params = { status: 'unknown' }
        schema = { status: { in: %w[active inactive] } }

        expect do
          controller.validate_param_schema(schema)
        end.to raise_error(BetterController::Error, /status must be one of/)
      end
    end

    context 'with format validation' do
      it 'passes when format matches' do
        controller.params = { email: 'test@example.com' }
        schema = { email: { format: /@/ } }

        expect(controller.validate_param_schema(schema)).to be true
      end

      it 'fails when format does not match' do
        controller.params = { email: 'invalid' }
        schema = { email: { format: /@/ } }

        expect do
          controller.validate_param_schema(schema)
        end.to raise_error(BetterController::Error, /email has invalid format/)
      end
    end

    context 'with multiple validations' do
      it 'collects all errors' do
        controller.params = { name: nil, count: 'abc' }
        schema = {
          name: { required: true },
          count: { type: Integer }
        }

        expect do
          controller.validate_param_schema(schema)
        end.to raise_error(BetterController::Error, /name is required.*count must be a/m)
      end
    end

    context 'with multiple params' do
      it 'validates all params' do
        controller.params = { name: 'Test', age: 25, status: 'active' }
        schema = {
          name: { required: true },
          age: { type: Integer },
          status: { in: %w[active inactive] }
        }

        expect(controller.validate_param_schema(schema)).to be true
      end
    end
  end

  describe '#parameter_present?' do
    it 'returns true for string key' do
      controller.params = { 'name' => 'Test' }

      expect(controller.send(:parameter_present?, :name)).to be true
    end

    it 'returns true for symbol key' do
      controller.params = { name: 'Test' }

      expect(controller.send(:parameter_present?, :name)).to be true
    end

    it 'returns false when param not present' do
      controller.params = {}

      expect(controller.send(:parameter_present?, :name)).to be false
    end
  end

  describe 'ClassMethods' do
    describe '.requires_params' do
      let(:controller_with_callbacks) do
        Class.new do
          include BetterController::Utils::ParameterValidation

          attr_accessor :params, :before_actions

          def initialize
            @params = {}
            @before_actions = []
          end

          def self.before_action(only:, &block)
            @before_action_blocks ||= {}
            @before_action_blocks[only] = block
          end

          def self.before_action_blocks
            @before_action_blocks || {}
          end

          requires_params :create, :name, :email
        end
      end

      it 'registers a before_action' do
        expect(controller_with_callbacks.before_action_blocks[:create]).to be_a(Proc)
      end

      it 'executes validation when before_action is called' do
        instance = controller_with_callbacks.new
        instance.params = { name: 'Test', email: 'test@example.com' }

        # Execute the registered before_action block in instance context
        result = instance.instance_eval(&controller_with_callbacks.before_action_blocks[:create])

        expect(result).to be true
      end

      it 'raises error when required params are missing' do
        instance = controller_with_callbacks.new
        instance.params = { name: 'Test' }

        expect do
          instance.instance_eval(&controller_with_callbacks.before_action_blocks[:create])
        end.to raise_error(BetterController::Error, /email/)
      end
    end

    describe '.param_schema' do
      let(:controller_with_schema) do
        Class.new do
          include BetterController::Utils::ParameterValidation

          attr_accessor :params

          def initialize
            @params = {}
          end

          def self.before_action(only:, &block)
            @before_action_blocks ||= {}
            @before_action_blocks[only] = block
          end

          def self.before_action_blocks
            @before_action_blocks || {}
          end

          param_schema :update, {
            name: { required: true },
            age: { type: Integer }
          }
        end
      end

      it 'registers a before_action for schema validation' do
        expect(controller_with_schema.before_action_blocks[:update]).to be_a(Proc)
      end

      it 'executes schema validation when before_action is called' do
        instance = controller_with_schema.new
        instance.params = { name: 'Test', age: 25 }

        # Execute the registered before_action block in instance context
        result = instance.instance_eval(&controller_with_schema.before_action_blocks[:update])

        expect(result).to be true
      end

      it 'raises error when schema validation fails' do
        instance = controller_with_schema.new
        instance.params = { age: 'invalid' }

        expect do
          instance.instance_eval(&controller_with_schema.before_action_blocks[:update])
        end.to raise_error(BetterController::Error, /name is required/)
      end
    end
  end
end
