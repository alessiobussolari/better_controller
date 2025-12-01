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

      def action_name
        @action_name ||= 'index'
      end

      def action_name=(name)
        @action_name = name
      end

      def respond_to
        yield(FormatResponder.new(self))
      end

      def render(component_or_options = nil, options = {})
        if component_or_options.is_a?(Hash)
          @rendered = component_or_options
        else
          @rendered = options.merge(component: component_or_options)
        end
      end

      def redirect_to(path, options = {})
        @redirected_to = { path: path, options: options }
      end

      def head(status)
        @rendered = { head: status }
      end

      def render_to_string(content)
        content.to_s
      end

      def turbo_stream
        TurboStreamMock.new
      end

      def request
        @request ||= OpenStruct.new(headers: {})
      end

      def request=(req)
        @request = req
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

    def csv
      yield if block_given?
    end

    def xml
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
      # Mock service class method to return a result
      # The action DSL uses class method if it responds to the method
      allow(ExampleService).to receive(:call).and_return(
        { success: true, collection: [] }
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

    it 'returns nil when no page is configured' do
      result = { success: true, resource: 'data' }

      page_config = controller.send(:resolve_page_config, config, result)

      expect(page_config).to be_nil
    end

    it 'calls execute_page when page is configured' do
      mock_page_class = Class.new do
        def initialize(data, user: nil)
          @data = data
          @user = user
        end

        def index
          { type: :index, title: 'Users' }
        end
      end

      config_with_page = { page: mock_page_class }
      result = { success: true, collection: [1, 2, 3] }

      controller.action_name = 'index'
      page_config = controller.send(:resolve_page_config, config_with_page, result)

      # Hash results are now wrapped in BetterController::Config
      expect(page_config).to be_a(BetterController::Config)
      expect(page_config[:type]).to eq(:index)
      expect(page_config[:title]).to eq('Users')
    end

    it 'returns nil when using component only' do
      component_config = { component: Class.new }

      page_config = controller.send(:resolve_page_config, component_config, nil)

      expect(page_config).to be_nil
    end
  end

  describe '#normalize_result' do
    it 'returns empty hash for nil' do
      expect(controller.send(:normalize_result, nil)).to eq({})
    end

    it 'returns hash as-is' do
      result = { success: true }
      expect(controller.send(:normalize_result, result)).to eq(result)
    end

    it 'converts object with to_h to hash' do
      result_obj = double('result', to_h: { resource: 'data' })
      expect(controller.send(:normalize_result, result_obj)).to eq({ resource: 'data' })
    end

    it 'returns empty hash for object without to_h' do
      result_obj = double('result')
      expect(controller.send(:normalize_result, result_obj)).to eq({})
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

      expect(result[:params][:id]).to eq(42)
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

    context 'when turbo_frame_request? returns true' do
      let(:mock_view_component) do
        Class.new do
          attr_reader :config

          def initialize(config:)
            @config = config
          end
        end
      end

      before do
        allow(controller).to receive(:respond_to?).and_call_original
        allow(controller).to receive(:respond_to?).with(:turbo_frame_request?, true).and_return(true)
        controller.define_singleton_method(:turbo_frame_request?) { true }
      end

      it 'renders with Rails standard render when no klass present' do
        controller.send(:render_page_or_component, {})

        expect(controller.rendered[:status]).to eq(:ok)
        expect(controller.rendered).not_to have_key(:layout)
      end

      it 'renders with Rails standard render even when page_config has klass (use turbo_frame DSL for explicit control)' do
        controller.instance_variable_set(:@page_config, { type: :index, klass: mock_view_component })
        controller.send(:render_page_or_component, {})

        # With new explicit DSL, render_page_or_component always does Rails standard render
        # Use turbo_frame {} DSL handler for explicit Turbo Frame control
        expect(controller.rendered[:status]).to eq(:ok)
        expect(controller.rendered).not_to have_key(:component)
      end
    end

    context 'when turbo_frame_request? returns false' do
      before do
        allow(controller).to receive(:respond_to?).and_call_original
        allow(controller).to receive(:respond_to?).with(:turbo_frame_request?, true).and_return(true)
        controller.define_singleton_method(:turbo_frame_request?) { false }
      end

      it 'renders with Rails standard render (no layout specified)' do
        controller.send(:render_page_or_component, {})

        expect(controller.rendered[:status]).to eq(:ok)
        expect(controller.rendered).not_to have_key(:layout)
      end
    end

    context 'when turbo_frame_request? is not available' do
      before do
        allow(controller).to receive(:respond_to?).and_call_original
        allow(controller).to receive(:respond_to?).with(:turbo_frame_request?, true).and_return(false)
      end

      it 'renders with Rails standard render (no layout specified)' do
        controller.send(:render_page_or_component, {})

        expect(controller.rendered[:status]).to eq(:ok)
        expect(controller.rendered).not_to have_key(:layout)
      end
    end
  end

  describe '#handle_action_success' do
    let(:config) { { on_success: {}, name: :create, error_handlers: {} } }

    before do
      controller.instance_variable_set(:@result, { success: true })
    end

    it 'calls set_success_flash' do
      expect(controller).to receive(:set_success_flash).with(config)
      controller.send(:handle_action_success, config)
    end

    it 'responds to html format' do
      controller.send(:handle_action_success, config)
      # Default render is called
      expect(controller.rendered).to be_present
    end
  end

  describe '#handle_html_success' do
    let(:config) { { component: nil } }

    context 'with redirect handler' do
      it 'redirects to path' do
        handlers = { redirect: { path: '/users', options: {} } }

        controller.send(:handle_html_success, config, handlers)

        expect(controller.redirected_to[:path]).to eq('/users')
      end
    end

    context 'with html block handler' do
      it 'executes the html block' do
        called = false
        handlers = { html: -> { called = true } }

        controller.send(:handle_html_success, config, handlers)

        expect(called).to be true
      end
    end

    context 'with render_page handler' do
      it 'renders page with status' do
        handlers = { render_page: { status: :created } }

        controller.send(:handle_html_success, config, handlers)

        expect(controller.rendered[:status]).to eq(:created)
      end
    end

    context 'with render_component handler' do
      let(:component_class) do
        Class.new do
          def initialize(**args)
            @args = args
          end
        end
      end

      it 'renders component' do
        handlers = { render_component: { component: component_class, locals: {} } }

        controller.send(:handle_html_success, config, handlers)

        expect(controller.rendered).to be_present
      end
    end
  end

  describe '#handle_turbo_stream_success' do
    let(:config) { {} }

    context 'with custom turbo_stream handler' do
      it 'renders custom turbo streams' do
        handlers = { turbo_stream: [{ action: :update, target: :flash }] }

        controller.send(:handle_turbo_stream_success, config, handlers)

        expect(controller.rendered).to be_present
      end
    end

    context 'without custom handler' do
      it 'renders default turbo success' do
        handlers = {}

        controller.send(:handle_turbo_stream_success, config, handlers)

        expect(controller.rendered).to be_present
      end
    end
  end

  describe '#handle_json_success' do
    let(:config) { {} }

    context 'with custom json handler' do
      it 'executes the json block' do
        called = false
        handlers = { json: -> { called = true } }

        controller.send(:handle_json_success, config, handlers)

        expect(called).to be true
      end
    end

    context 'without custom handler' do
      it 'renders json response' do
        controller.instance_variable_set(:@result, { success: true, data: 'test' })
        handlers = {}

        controller.send(:handle_json_success, config, handlers)

        expect(controller.rendered[:json]).to eq({ success: true, data: 'test' })
      end
    end
  end

  describe 'Turbo Frame DSL handling' do
    let(:mock_component_class) do
      Class.new do
        attr_reader :args
        def initialize(**args)
          @args = args
        end
      end
    end

    describe '#handle_html_success with turbo_frame handler' do
      let(:config) { {} }

      before do
        # Simulate Turbo Frame request
        controller.request = OpenStruct.new(headers: { 'Turbo-Frame' => 'users_list' })
      end

      context 'when turbo_frame handler is defined with component' do
        it 'renders the component with layout: false' do
          handlers = {
            turbo_frame: {
              config: { type: :component, klass: mock_component_class, locals: { title: 'Users' } },
              layout: false
            }
          }

          controller.send(:handle_html_success, config, handlers)

          expect(controller.rendered[:component]).to be_a(mock_component_class)
          expect(controller.rendered[:layout]).to eq(false)
        end

        it 'passes locals to component' do
          handlers = {
            turbo_frame: {
              config: { type: :component, klass: mock_component_class, locals: { title: 'Users', count: 10 } },
              layout: false
            }
          }

          controller.send(:handle_html_success, config, handlers)

          component = controller.rendered[:component]
          expect(component.args[:title]).to eq('Users')
          expect(component.args[:count]).to eq(10)
        end

        it 'respects custom layout setting' do
          handlers = {
            turbo_frame: {
              config: { type: :component, klass: mock_component_class, locals: {} },
              layout: true
            }
          }

          controller.send(:handle_html_success, config, handlers)

          expect(controller.rendered[:layout]).to eq(true)
        end
      end

      context 'when turbo_frame handler is defined with partial' do
        it 'renders the partial with layout: false' do
          handlers = {
            turbo_frame: {
              config: { type: :partial, path: 'users/list', locals: { users: [] } },
              layout: false
            }
          }

          controller.send(:handle_html_success, config, handlers)

          expect(controller.rendered[:partial]).to eq('users/list')
          expect(controller.rendered[:locals]).to eq({ users: [] })
          expect(controller.rendered[:layout]).to eq(false)
        end
      end

      context 'when turbo_frame handler is defined with render_page' do
        it 'renders the page config' do
          page_config = { type: :index, title: 'Users' }
          controller.instance_variable_set(:@page_config, page_config)

          handlers = {
            turbo_frame: {
              config: { type: :page, status: :ok },
              layout: false
            }
          }

          controller.send(:handle_html_success, config, handlers)

          expect(controller.rendered[:status]).to eq(:ok)
          expect(controller.rendered[:layout]).to eq(false)
        end

        it 'uses custom status from render_page' do
          handlers = {
            turbo_frame: {
              config: { type: :page, status: :created },
              layout: false
            }
          }

          controller.send(:handle_html_success, config, handlers)

          expect(controller.rendered[:status]).to eq(:created)
        end
      end

      context 'when no turbo_frame handler but html handler exists' do
        it 'falls back to html handler (Rails standard behavior)' do
          html_called = false
          handlers = {
            html: -> { html_called = true }
          }

          controller.send(:handle_html_success, config, handlers)

          expect(html_called).to be true
        end
      end
    end

    describe '#is_turbo_frame_request?' do
      context 'when Turbo-Frame header is present' do
        before do
          controller.request = OpenStruct.new(headers: { 'Turbo-Frame' => 'users_list' })
        end

        it 'returns true' do
          expect(controller.send(:is_turbo_frame_request?)).to be true
        end
      end

      context 'when Turbo-Frame header is absent' do
        before do
          controller.request = OpenStruct.new(headers: {})
        end

        it 'returns false' do
          expect(controller.send(:is_turbo_frame_request?)).to be false
        end
      end

      context 'when request is not available' do
        before do
          # Remove request method
          controller.singleton_class.undef_method(:request) if controller.respond_to?(:request)
        end

        it 'returns false without raising' do
          expect(controller.send(:is_turbo_frame_request?)).to be false
        end
      end
    end

    describe '#handle_turbo_frame_response' do
      context 'with component config' do
        it 'renders component with layout false by default' do
          frame_config = {
            config: { type: :component, klass: mock_component_class, locals: {} },
            layout: false
          }

          controller.send(:handle_turbo_frame_response, frame_config)

          expect(controller.rendered[:component]).to be_a(mock_component_class)
          expect(controller.rendered[:layout]).to eq(false)
        end
      end

      context 'with partial config' do
        it 'renders partial with locals' do
          frame_config = {
            config: { type: :partial, path: 'users/card', locals: { user: { name: 'John' } } },
            layout: false
          }

          controller.send(:handle_turbo_frame_response, frame_config)

          expect(controller.rendered[:partial]).to eq('users/card')
          expect(controller.rendered[:locals]).to eq({ user: { name: 'John' } })
        end
      end

      context 'with page config' do
        it 'renders page config with status' do
          page = { type: :show }
          controller.instance_variable_set(:@page_config, page)

          frame_config = {
            config: { type: :page, status: :ok },
            layout: false
          }

          controller.send(:handle_turbo_frame_response, frame_config)

          expect(controller.rendered[:status]).to eq(:ok)
        end
      end
    end

    describe '#handle_turbo_frame_error_response' do
      context 'with component config' do
        it 'renders component with error status' do
          frame_config = {
            config: { type: :component, klass: mock_component_class, locals: {} },
            layout: false
          }

          controller.send(:handle_turbo_frame_error_response, frame_config, :unprocessable_entity)

          expect(controller.rendered[:component]).to be_a(mock_component_class)
          expect(controller.rendered[:status]).to eq(:unprocessable_entity)
        end
      end

      context 'with partial config' do
        it 'renders partial with error status' do
          frame_config = {
            config: { type: :partial, path: 'errors/form', locals: { errors: ['Invalid'] } },
            layout: false
          }

          controller.send(:handle_turbo_frame_error_response, frame_config, :unprocessable_entity)

          expect(controller.rendered[:partial]).to eq('errors/form')
          expect(controller.rendered[:status]).to eq(:unprocessable_entity)
        end
      end

      context 'with page config' do
        it 'uses status from frame config when specified' do
          frame_config = {
            config: { type: :page, status: :bad_request },
            layout: false
          }

          controller.send(:handle_turbo_frame_error_response, frame_config, :unprocessable_entity)

          # Status from frame config takes precedence when specified
          expect(controller.rendered[:status]).to eq(:bad_request)
        end

        it 'falls back to error status when config status is nil' do
          frame_config = {
            config: { type: :page, status: nil },
            layout: false
          }

          controller.send(:handle_turbo_frame_error_response, frame_config, :unprocessable_entity)

          # Falls back to error status
          expect(controller.rendered[:status]).to eq(:unprocessable_entity)
        end
      end
    end
  end

  describe '#handle_action_error' do
    let(:config) { { name: :create, error_handlers: {} } }

    before do
      controller.instance_variable_set(:@result, { success: false, errors: { name: ["can't be blank"] } })
    end

    it 'calls set_error_flash' do
      expect(controller).to receive(:set_error_flash).with(:validation, config)
      controller.send(:handle_action_error, config)
    end
  end

  describe '#handle_html_error' do
    let(:config) { { component: nil } }

    context 'with redirect handler' do
      it 'redirects to path' do
        handlers = { redirect: { path: '/users', options: {} } }

        controller.send(:handle_html_error, config, handlers, :validation)

        expect(controller.redirected_to[:path]).to eq('/users')
      end
    end

    context 'with html block handler' do
      it 'executes the html block with error' do
        received_error = nil
        error = StandardError.new('Test error')
        controller.instance_variable_set(:@error, error)
        handlers = { html: ->(e) { received_error = e } }

        controller.send(:handle_html_error, config, handlers, :validation)

        expect(received_error).to eq(error)
      end
    end

    context 'with render_page handler' do
      it 'renders page with custom status' do
        handlers = { render_page: { status: :bad_request } }

        controller.send(:handle_html_error, config, handlers, :validation)

        expect(controller.rendered[:status]).to eq(:bad_request)
      end

      it 'uses error status when no custom status' do
        handlers = { render_page: {} }

        controller.send(:handle_html_error, config, handlers, :not_found)

        expect(controller.rendered[:status]).to eq(:not_found)
      end
    end

    context 'without handlers' do
      it 'renders with error status' do
        handlers = {}

        controller.send(:handle_html_error, config, handlers, :validation)

        expect(controller.rendered[:status]).to eq(:unprocessable_entity)
      end
    end
  end

  describe '#handle_turbo_stream_error' do
    let(:config) { {} }

    context 'with custom turbo_stream handler' do
      it 'renders custom turbo streams' do
        handlers = { turbo_stream: [{ action: :update, target: :errors }] }

        controller.send(:handle_turbo_stream_error, config, handlers)

        expect(controller.rendered).to be_present
      end
    end

    context 'without custom handler' do
      it 'renders default turbo error' do
        handlers = {}
        controller.instance_variable_set(:@result, { errors: { name: ["can't be blank"] } })

        controller.send(:handle_turbo_stream_error, config, handlers)

        expect(controller.rendered).to be_present
      end
    end
  end

  describe '#handle_json_error' do
    let(:config) { {} }

    context 'with custom json handler' do
      it 'executes the json block with error' do
        received_error = nil
        error = StandardError.new('Test error')
        controller.instance_variable_set(:@error, error)
        handlers = { json: ->(e) { received_error = e } }

        controller.send(:handle_json_error, config, handlers, :validation)

        expect(received_error).to eq(error)
      end
    end

    context 'without custom handler' do
      it 'renders json error response with status' do
        controller.instance_variable_set(:@result, { success: false })
        controller.instance_variable_set(:@error, StandardError.new('Something failed'))
        handlers = {}

        controller.send(:handle_json_error, config, handlers, :not_found)

        expect(controller.rendered[:json][:success]).to be false
        expect(controller.rendered[:json][:error]).to eq('Something failed')
        expect(controller.rendered[:status]).to eq(:not_found)
      end
    end
  end

  describe '#redirect_to_path' do
    context 'with string path' do
      it 'redirects to the path' do
        config = { path: '/users/1', options: { notice: 'Success' } }

        controller.send(:redirect_to_path, config)

        expect(controller.redirected_to[:path]).to eq('/users/1')
        expect(controller.redirected_to[:options]).to eq({ notice: 'Success' })
      end
    end

    context 'with symbol path' do
      it 'calls the method and redirects' do
        controller.define_singleton_method(:users_path) { '/users' }
        config = { path: :users_path, options: {} }

        controller.send(:redirect_to_path, config)

        expect(controller.redirected_to[:path]).to eq('/users')
      end
    end
  end

  describe '#set_success_flash' do
    it 'sets flash notice when translation exists' do
      allow(I18n).to receive(:t).and_call_original
      allow(I18n).to receive(:t)
        .with('flash.users.create.success', default: anything)
        .and_return('User created successfully')

      controller.send(:set_success_flash, { name: :create })

      expect(controller.flash[:notice]).to eq('User created successfully')
    end

    it 'does nothing when translation is nil' do
      allow(I18n).to receive(:t).and_return(nil)

      controller.send(:set_success_flash, { name: :create })

      expect(controller.flash[:notice]).to be_nil
    end
  end

  describe '#set_error_flash' do
    it 'sets flash alert when translation exists' do
      allow(I18n).to receive(:t).and_call_original
      allow(I18n).to receive(:t)
        .with('flash.users.create.validation', default: anything)
        .and_return('Validation failed')

      controller.send(:set_error_flash, :validation, { name: :create })

      expect(controller.flash[:alert]).to eq('Validation failed')
    end

    it 'does nothing when translation is nil' do
      allow(I18n).to receive(:t).and_return(nil)

      controller.send(:set_error_flash, :validation, { name: :create })

      expect(controller.flash[:alert]).to be_nil
    end
  end

  describe '#build_service_instance' do
    let(:service_with_zero_arity) do
      Class.new do
        def initialize; end
      end
    end

    let(:service_with_user) do
      Class.new do
        attr_reader :user, :options

        def initialize(user, **options)
          @user = user
          @options = options
        end
      end
    end

    let(:service_with_options) do
      Class.new do
        attr_reader :options

        def initialize(**options)
          @options = options
        end
      end
    end

    it 'instantiates service with zero arity' do
      service = controller.send(:build_service_instance, service_with_zero_arity, {})

      expect(service).to be_a(service_with_zero_arity)
    end

    it 'instantiates service with current_user when available' do
      service = controller.send(:build_service_instance, service_with_user, { params: { name: 'Test' } })

      expect(service.user.name).to eq('Test User')
      expect(service.options[:params]).to eq({ name: 'Test' })
    end
  end

  describe '#resolve_turbo_content' do
    context 'with component' do
      let(:component_class) do
        Class.new do
          def initialize(**args)
            @args = args
          end

          def to_s
            '<div>Component</div>'
          end
        end
      end

      it 'renders component to string' do
        stream = { component: component_class, locals: {} }

        result = controller.send(:resolve_turbo_content, stream)

        expect(result).to be_present
      end
    end

    context 'with partial' do
      it 'renders partial to string' do
        stream = { partial: 'shared/flash', locals: { message: 'Test' } }

        # Mock render_to_string
        allow(controller).to receive(:render_to_string)
          .with(partial: 'shared/flash', locals: { message: 'Test' })
          .and_return('<div>Flash</div>')

        result = controller.send(:resolve_turbo_content, stream)

        expect(result).to eq('<div>Flash</div>')
      end
    end

    context 'without component or partial' do
      it 'returns nil' do
        stream = { action: :remove, target: :item }

        result = controller.send(:resolve_turbo_content, stream)

        expect(result).to be_nil
      end
    end
  end

  describe '#render_default_turbo_success' do
    it 'renders flash update stream' do
      controller.send(:render_default_turbo_success)

      expect(controller.rendered).to be_present
    end
  end

  describe '#render_default_turbo_error' do
    it 'renders flash update stream' do
      controller.send(:render_default_turbo_error)

      expect(controller.rendered).to be_present
    end

    it 'includes form errors when present' do
      controller.instance_variable_set(:@result, { errors: { name: ["can't be blank"] } })

      controller.send(:render_default_turbo_error)

      expect(controller.rendered).to be_present
    end
  end

  describe '#render_page_config' do
    it 'assigns page_config and renders with status' do
      page_config = { type: :show, title: 'User' }

      controller.send(:render_page_config, page_config, status: :ok)

      expect(controller.instance_variable_get(:@page_config)).to eq(page_config)
      expect(controller.rendered[:status]).to eq(:ok)
    end
  end

  describe '#render_configured_component' do
    let(:component_class) do
      Class.new do
        def initialize(**args)
          @args = args
        end
      end
    end

    it 'renders component with merged locals' do
      controller.instance_variable_set(:@result, { success: true, resource: 'user' })
      config = { component: component_class, locals: { extra: 'data' }, status: :created }

      controller.send(:render_configured_component, config)

      expect(controller.rendered[:status]).to eq(:created)
    end

    it 'uses default status when not specified' do
      config = { component: component_class }

      controller.send(:render_configured_component, config)

      expect(controller.rendered[:status]).to eq(:ok)
    end
  end

  describe '#normalize_page_config' do
    before do
      BetterController.reset_config!
    end

    after do
      BetterController.reset_config!
    end

    it 'returns nil for nil input' do
      expect(controller.send(:normalize_page_config, nil)).to be_nil
    end

    it 'returns BetterController::Config as-is' do
      config = BetterController::Config.new({ type: :index })

      result = controller.send(:normalize_page_config, config)

      expect(result).to be(config)
      expect(result).to be_a(BetterController::Config)
    end

    it 'wraps Hash in BetterController::Config' do
      hash = { type: :index, title: 'Users' }

      result = controller.send(:normalize_page_config, hash)

      expect(result).to be_a(BetterController::Config)
      expect(result[:type]).to eq(:index)
      expect(result[:title]).to eq('Users')
    end

    context 'with custom page_config_class configured' do
      let(:custom_config_class) do
        Class.new do
          attr_reader :data

          def initialize(data)
            @data = data
          end
        end
      end

      before do
        BetterController.configure do |config|
          config.page_config_class = custom_config_class
        end
      end

      it 'returns custom class instance as-is' do
        custom_instance = custom_config_class.new({ type: :show })

        result = controller.send(:normalize_page_config, custom_instance)

        expect(result).to be(custom_instance)
      end

      it 'still returns BetterController::Config as-is' do
        config = BetterController::Config.new({ type: :index })

        result = controller.send(:normalize_page_config, config)

        expect(result).to be(config)
      end

      it 'still wraps Hash in BetterController::Config when custom class not matched' do
        hash = { type: :index }

        result = controller.send(:normalize_page_config, hash)

        expect(result).to be_a(BetterController::Config)
      end
    end

    it 'returns other objects as-is' do
      other_object = double('custom_config')

      result = controller.send(:normalize_page_config, other_object)

      expect(result).to be(other_object)
    end
  end

  describe '#execute_page with normalize_page_config' do
    let(:mock_page_class) do
      Class.new do
        def initialize(data, user: nil)
          @data = data
          @user = user
        end

        def index
          { type: :index, title: 'Users List' }
        end
      end
    end

    before do
      BetterController.reset_config!
      controller.action_name = 'index'
    end

    after do
      BetterController.reset_config!
    end

    it 'wraps hash result in BetterController::Config' do
      result = { success: true, collection: [1, 2, 3] }

      page_config = controller.send(:execute_page, mock_page_class, result)

      expect(page_config).to be_a(BetterController::Config)
      expect(page_config[:type]).to eq(:index)
      expect(page_config[:title]).to eq('Users List')
    end

    context 'when page returns BetterController::Config' do
      let(:config_returning_page_class) do
        Class.new do
          def initialize(data, user: nil)
            @data = data
            @user = user
          end

          def index
            BetterController::Config.new({ type: :index, title: 'Direct Config' })
          end
        end
      end

      it 'returns the config as-is' do
        result = { success: true, collection: [1, 2, 3] }

        page_config = controller.send(:execute_page, config_returning_page_class, result)

        expect(page_config).to be_a(BetterController::Config)
        expect(page_config[:title]).to eq('Direct Config')
      end
    end
  end
end

