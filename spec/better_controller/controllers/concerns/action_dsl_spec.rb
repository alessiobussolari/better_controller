# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

# Mock error classes for testing
module TestErrors
  class RecordNotFoundError < StandardError
    def self.name
      'ActiveRecord::RecordNotFound'
    end
  end

  class RecordInvalidError < StandardError
    def self.name
      'ActiveRecord::RecordInvalid'
    end

    def initialize(record = nil)
      @record = record
      super('Record invalid')
    end
  end
end

RSpec.describe BetterController::Controllers::Concerns::ActionDsl do
  # Create a test controller class
  let(:controller_class) do
    Class.new do
      include BetterController::Controllers::Concerns::ActionDsl

      attr_accessor :params, :flash, :rendered, :redirected_to

      def initialize
        @params = {}
        @flash = {}
        @rendered = nil
        @redirected_to = nil
      end

      def current_user
        @current_user ||= OpenStruct.new(id: 1, name: 'Test User')
      end

      def controller_name
        'users'
      end

      def respond_to
        yield(FormatResponder.new(self))
      end

      def render(options = {})
        @rendered = options
      end

      def redirect_to(path, options = {})
        @redirected_to = { path: path, options: options }
      end

      def render_to_string(content)
        content.to_s
      end

      def turbo_stream
        TurboStreamMock.new
      end

      def helpers
        OpenStruct.new(dom_id: ->(obj, prefix = nil) { "#{prefix}_#{obj.class.name.downcase}_#{obj.id}" })
      end
    end
  end

  # Mock format responder
  class FormatResponder
    def initialize(controller)
      @controller = controller
    end

    def html
      yield if block_given?
    end

    def turbo_stream
      yield if block_given?
    end

    def json
      yield if block_given?
    end
  end

  # Mock turbo_stream helper
  class TurboStreamMock
    def update(target, options = {})
      { action: :update, target: target, options: options }
    end

    def remove(target)
      { action: :remove, target: target }
    end

    def append(target, content = nil)
      { action: :append, target: target, content: content }
    end

    def prepend(target, content = nil)
      { action: :prepend, target: target, content: content }
    end

    def replace(target, content = nil)
      { action: :replace, target: target, content: content }
    end

    def refresh
      { action: :refresh }
    end

    def method_missing(method, *args)
      { action: method, args: args }
    end

    def respond_to_missing?(*)
      true
    end
  end

  let(:controller) { controller_class.new }

  describe '.action' do
    it 'registers an action with configuration' do
      controller_class.action(:index) do
        service ExampleService
      end

      expect(controller_class._registered_actions[:index]).to be_a(Hash)
      expect(controller_class._registered_actions[:index][:service]).to eq(ExampleService)
    end

    it 'defines a method for the action' do
      controller_class.action(:show) do
        service ExampleService
      end

      expect(controller_class.instance_methods).to include(:show)
    end

    it 'supports action without service' do
      page_class = Class.new
      controller_class.action(:help) do
        page page_class
      end

      expect(controller_class._registered_actions[:help][:page]).to eq(page_class)
    end

    it 'supports action with component' do
      component_class = Class.new
      controller_class.action(:dashboard) do
        component component_class
      end

      expect(controller_class._registered_actions[:dashboard][:component]).to eq(component_class)
    end
  end

  describe '#execute_registered_action' do
    before do
      controller_class.action(:index) do
        service ExampleService
      end
    end

    it 'executes the service and sets result' do
      # Mock service to return a result
      allow(ExampleService).to receive(:new).and_return(
        double(call: { success: true, collection: [] })
      )

      controller.send(:execute_registered_action, :index)

      expect(controller.instance_variable_get(:@result)).to eq({ success: true, collection: [] })
    end

    it 'raises error for unregistered action' do
      expect do
        controller.send(:execute_registered_action, :unknown)
      end.to raise_error(BetterController::Controllers::Concerns::ActionNotRegisteredError)
    end
  end

  describe '#resolve_page_config' do
    let(:config) { { service: ExampleService } }

    it 'returns page_config from service result' do
      result = { success: true, page_config: { type: :index, title: 'Users' } }

      page_config = controller.send(:resolve_page_config, config, result)

      expect(page_config).to eq({ type: :index, title: 'Users' })
    end

    it 'applies page_config_modifier if present' do
      result = { success: true, page_config: { type: :index, title: 'Users' } }
      config[:page_config_modifier] = proc { |c| c[:title] = 'Modified' }

      page_config = controller.send(:resolve_page_config, config, result)

      expect(page_config[:title]).to eq('Modified')
    end

    it 'returns nil when using component only' do
      component_config = { component: Class.new }

      page_config = controller.send(:resolve_page_config, component_config, nil)

      expect(page_config).to be_nil
    end
  end

  describe '#action_successful?' do
    it 'returns true when result has success: true' do
      result = { success: true }

      expect(controller.send(:action_successful?, result)).to be true
    end

    it 'returns false when result has success: false' do
      result = { success: false }

      expect(controller.send(:action_successful?, result)).to be false
    end

    it 'returns false when error is present' do
      controller.instance_variable_set(:@error, StandardError.new)

      expect(controller.send(:action_successful?, { success: true })).to be false
    end

    it 'returns true when result is nil' do
      expect(controller.send(:action_successful?, nil)).to be true
    end
  end

  describe '#classify_error' do
    it 'returns :not_found for ActiveRecord::RecordNotFound' do
      error = TestErrors::RecordNotFoundError.new

      expect(controller.send(:classify_error, error)).to eq(:not_found)
    end

    it 'returns :validation for ActiveRecord::RecordInvalid' do
      model = ExampleModel.new
      error = TestErrors::RecordInvalidError.new(model)

      expect(controller.send(:classify_error, error)).to eq(:validation)
    end

    it 'returns :any for unknown errors' do
      error = StandardError.new

      expect(controller.send(:classify_error, error)).to eq(:any)
    end
  end

  describe '#error_status' do
    it 'returns :not_found for :not_found type' do
      expect(controller.send(:error_status, :not_found)).to eq(:not_found)
    end

    it 'returns :forbidden for :authorization type' do
      expect(controller.send(:error_status, :authorization)).to eq(:forbidden)
    end

    it 'returns :unprocessable_entity for :validation type' do
      expect(controller.send(:error_status, :validation)).to eq(:unprocessable_entity)
    end

    it 'returns :internal_server_error for :any type' do
      expect(controller.send(:error_status, :any)).to eq(:internal_server_error)
    end
  end

  describe '#build_json_response' do
    it 'removes page_config from result' do
      result = { success: true, data: 'test', page_config: { type: :index } }

      json = controller.send(:build_json_response, result)

      expect(json).to eq({ success: true, data: 'test' })
    end

    it 'returns empty hash for nil result' do
      expect(controller.send(:build_json_response, nil)).to eq({})
    end
  end

  describe '#build_json_error_response' do
    it 'builds error response with message' do
      error = StandardError.new('Something went wrong')

      response = controller.send(:build_json_error_response, nil, error)

      expect(response[:success]).to be false
      expect(response[:error]).to eq('Something went wrong')
    end

    it 'includes errors from result' do
      result = { errors: { name: ["can't be blank"] } }

      response = controller.send(:build_json_error_response, result, nil)

      expect(response[:errors]).to eq({ name: ["can't be blank"] })
    end

    it 'returns default error when both are nil' do
      response = controller.send(:build_json_error_response, nil, nil)

      expect(response[:error]).to eq('An error occurred')
    end
  end

  describe '#execute_callbacks' do
    it 'does nothing when callbacks are nil' do
      expect { controller.send(:execute_callbacks, nil) }.not_to raise_error
    end

    it 'does nothing when callbacks are empty' do
      expect { controller.send(:execute_callbacks, []) }.not_to raise_error
    end

    it 'executes all callbacks' do
      called = []
      callbacks = [
        -> { called << 1 },
        -> { called << 2 }
      ]

      controller.send(:execute_callbacks, callbacks)

      expect(called).to eq([1, 2])
    end

    it 'passes arguments to callbacks' do
      received = nil
      callbacks = [->(arg) { received = arg }]

      controller.send(:execute_callbacks, callbacks, 'test_arg')

      expect(received).to eq('test_arg')
    end
  end

  describe '#build_service_params' do
    it 'includes params key' do
      controller.params = { user: { name: 'Test' } }
      config = { params_key: :user }

      result = controller.send(:build_service_params, config)

      expect(result).to have_key(:params)
    end

    it 'includes id when present' do
      controller.params = { id: 42, user: { name: 'Test' } }
      config = {}

      result = controller.send(:build_service_params, config)

      expect(result[:id]).to eq(42)
    end
  end

  describe '#action_params' do
    it 'returns empty hash when params not present' do
      controller.params = nil

      result = controller.send(:action_params, {})

      expect(result).to eq({})
    end

    it 'returns params key when available' do
      controller.params = { user: { name: 'Test' } }
      config = { params_key: :user }

      result = controller.send(:action_params, config)

      expect(result).to eq({ name: 'Test' })
    end

    it 'returns all params when key not found' do
      controller.params = { name: 'Test' }
      config = { params_key: :user }

      result = controller.send(:action_params, config)

      expect(result).to eq({ name: 'Test' })
    end
  end

  describe '#deep_dup_config' do
    it 'returns non-hash values unchanged' do
      expect(controller.send(:deep_dup_config, 'string')).to eq('string')
    end

    it 'deep duplicates hash values' do
      original = { a: { b: 1 } }
      result = controller.send(:deep_dup_config, original)

      expect(result).to eq(original)
      expect(result).not_to be(original)
    end
  end

  describe '#determine_error_type' do
    it 'returns :validation when errors present' do
      result = { errors: { name: ["can't be blank"] } }

      expect(controller.send(:determine_error_type, result)).to eq(:validation)
    end

    it 'returns :any when no errors' do
      result = { success: false }

      expect(controller.send(:determine_error_type, result)).to eq(:any)
    end

    it 'returns :any when result is nil' do
      expect(controller.send(:determine_error_type, nil)).to eq(:any)
    end
  end

  describe '#find_error_handlers' do
    it 'returns handler for specific error type' do
      config = {
        error_handlers: {
          validation: { html: -> {} },
          any: { html: -> {} }
        }
      }

      result = controller.send(:find_error_handlers, config, :validation)

      expect(result).to eq({ html: config[:error_handlers][:validation][:html] })
    end

    it 'falls back to :any handler' do
      config = {
        error_handlers: {
          any: { html: -> {} }
        }
      }

      result = controller.send(:find_error_handlers, config, :validation)

      expect(result).to eq({ html: config[:error_handlers][:any][:html] })
    end

    it 'returns empty hash when no handlers' do
      config = { error_handlers: {} }

      result = controller.send(:find_error_handlers, config, :validation)

      expect(result).to eq({})
    end
  end

  describe '#build_component_locals' do
    it 'duplicates base locals' do
      base = { key: 'value' }
      result = controller.send(:build_component_locals, base)

      expect(result[:key]).to eq('value')
      expect(result).not_to be(base)
    end

    it 'adds result when present' do
      controller.instance_variable_set(:@result, { success: true })

      result = controller.send(:build_component_locals, {})

      expect(result[:result]).to eq({ success: true })
    end

    it 'adds resource from result' do
      controller.instance_variable_set(:@result, { resource: 'test_resource' })

      result = controller.send(:build_component_locals, {})

      expect(result[:resource]).to eq('test_resource')
    end

    it 'adds collection from result' do
      controller.instance_variable_set(:@result, { collection: [1, 2, 3] })

      result = controller.send(:build_component_locals, {})

      expect(result[:collection]).to eq([1, 2, 3])
    end
  end

  describe '#resolve_turbo_target' do
    it 'converts symbol to string' do
      expect(controller.send(:resolve_turbo_target, :users_list)).to eq('users_list')
    end

    it 'keeps string as is' do
      expect(controller.send(:resolve_turbo_target, 'my_target')).to eq('my_target')
    end
  end

  describe '#build_turbo_streams' do
    it 'maps stream configs to built streams' do
      streams = [
        { action: :update, target: :flash },
        { action: :remove, target: :item }
      ]

      result = controller.send(:build_turbo_streams, streams)

      expect(result.length).to eq(2)
    end
  end

  describe '#build_single_turbo_stream' do
    it 'builds remove stream' do
      stream = { action: :remove, target: :item }

      result = controller.send(:build_single_turbo_stream, stream)

      expect(result[:action]).to eq(:remove)
    end

    it 'builds refresh stream' do
      stream = { action: :refresh, target: :page }

      result = controller.send(:build_single_turbo_stream, stream)

      expect(result[:action]).to eq(:refresh)
    end

    it 'builds update stream with content' do
      stream = { action: :update, target: :flash, partial: 'shared/flash' }

      result = controller.send(:build_single_turbo_stream, stream)

      expect(result[:action]).to eq(:update)
    end
  end

  describe '#render_page_or_component' do
    it 'renders default when no page_config or component' do
      config = {}

      controller.send(:render_page_or_component, config)

      expect(controller.rendered[:status]).to eq(:ok)
    end

    it 'renders with custom status' do
      config = {}

      controller.send(:render_page_or_component, config, status: :created)

      expect(controller.rendered[:status]).to eq(:created)
    end
  end
end

