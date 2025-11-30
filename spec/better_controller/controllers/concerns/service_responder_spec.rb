# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Controllers::Concerns::ServiceResponder do
  let(:controller_class) do
    Class.new do
      include BetterController::Controllers::Concerns::ServiceResponder

      attr_accessor :flash, :rendered, :redirected_to, :format_type

      def initialize
        @flash = {}
        @rendered = nil
        @redirected_to = nil
        @format_type = :html
      end

      def respond_to
        responder = MockFormatResponder.new(@format_type, self)
        yield(responder)
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
        @helpers ||= Object.new.tap do |h|
          def h.dom_id(obj, prefix = nil)
            prefix ? "#{prefix}_#{obj.class.name.downcase}_#{obj.id}" : "#{obj.class.name.downcase}_#{obj.id}"
          end
        end
      end

      def controller_name
        'users'
      end

      def users_path
        '/users'
      end
    end
  end

  # Mock format responder
  class MockFormatResponder
    def initialize(format_type, controller)
      @format_type = format_type
      @controller = controller
    end

    def html
      yield if block_given? && @format_type == :html
    end

    def turbo_stream
      yield if block_given? && @format_type == :turbo_stream
    end

    def json
      yield if block_given? && @format_type == :json
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

    def prepend(target, options = {})
      { action: :prepend, target: target, options: options }
    end

    def replace(target, options = {})
      { action: :replace, target: target, options: options }
    end
  end

  let(:controller) { controller_class.new }

  describe '#respond_with_service' do
    context 'when result is successful' do
      let(:result) { { success: true, message: 'Success!' } }

      it 'sets @service_result' do
        controller.respond_with_service(result)

        expect(controller.instance_variable_get(:@service_result)).to eq(result)
      end

      it 'sets flash notice' do
        controller.respond_with_service(result)

        expect(controller.flash[:notice]).to eq('Success!')
      end

      it 'redirects to success_path when provided' do
        controller.respond_with_service(result, success_path: '/dashboard')

        expect(controller.redirected_to[:path]).to eq('/dashboard')
      end

      it 'resolves symbol path' do
        controller.respond_with_service(result, success_path: :users_path)

        expect(controller.redirected_to[:path]).to eq('/users')
      end

      it 'uses redirect_to from result' do
        result[:redirect_to] = '/custom-path'
        controller.respond_with_service(result)

        expect(controller.redirected_to[:path]).to eq('/custom-path')
      end

      it 'renders page_config when present' do
        page_config = { type: :index, title: 'Users' }
        result[:page_config] = page_config
        controller.respond_with_service(result)

        expect(controller.instance_variable_get(:@page_config)).to eq(page_config)
      end

      it 'calls default render when no path or page_config' do
        controller.respond_with_service({ success: true })

        expect(controller.rendered).to eq({})
      end
    end

    context 'when result is failure' do
      let(:result) { { success: false, error: 'Something went wrong' } }

      it 'sets flash alert' do
        controller.respond_with_service(result)

        expect(controller.flash[:alert]).to eq('Something went wrong')
      end

      it 'redirects to failure_path when provided' do
        controller.respond_with_service(result, failure_path: '/error')

        expect(controller.redirected_to[:path]).to eq('/error')
      end

      it 'renders with unprocessable_entity status by default' do
        controller.respond_with_service(result)

        expect(controller.rendered[:status]).to eq(:unprocessable_entity)
      end
    end

    context 'with JSON format' do
      before { controller.format_type = :json }

      it 'renders JSON on success' do
        result = { success: true, data: { id: 1 } }
        controller.respond_with_service(result)

        expect(controller.rendered[:json]).to include(success: true, data: { id: 1 })
      end

      it 'renders JSON with error status on failure' do
        result = { success: false, error: 'Failed' }
        controller.respond_with_service(result)

        expect(controller.rendered[:json]).to include(success: false)
        expect(controller.rendered[:status]).to eq(:unprocessable_entity)
      end

      it 'removes internal keys from JSON response' do
        result = { success: true, page_config: {}, turbo_streams: [], redirect_to: '/path' }
        controller.respond_with_service(result)

        json = controller.rendered[:json]
        expect(json).not_to have_key(:page_config)
        expect(json).not_to have_key(:turbo_streams)
        expect(json).not_to have_key(:redirect_to)
      end
    end

    context 'with Turbo Stream format' do
      before { controller.format_type = :turbo_stream }

      it 'renders turbo_streams from result when provided' do
        streams = [{ action: :update, target: :content }]
        result = { success: true, turbo_streams: streams }
        controller.respond_with_service(result)

        expect(controller.rendered[:turbo_stream]).to eq(streams)
      end

      it 'builds default turbo streams on success' do
        result = { success: true }
        controller.respond_with_service(result)

        expect(controller.rendered[:turbo_stream]).to be_an(Array)
      end
    end
  end

  describe '#respond_with_page_config' do
    let(:page_config) { { type: :index, title: 'Users' } }
    let(:result) { { success: true, page_config: page_config } }

    it 'sets @page_config' do
      controller.respond_with_page_config(result)

      expect(controller.instance_variable_get(:@page_config)).to eq(page_config)
    end

    it 'sets @service_result' do
      controller.respond_with_page_config(result)

      expect(controller.instance_variable_get(:@service_result)).to eq(result)
    end

    it 'renders with :ok status on success' do
      controller.respond_with_page_config(result)

      expect(controller.rendered[:status]).to eq(:ok)
    end

    it 'renders with :unprocessable_entity on failure' do
      result[:success] = false
      controller.respond_with_page_config(result)

      expect(controller.rendered[:status]).to eq(:unprocessable_entity)
    end
  end

  describe '#set_service_flash' do
    it 'sets flash message when present' do
      controller.send(:set_service_flash, :notice, 'Hello')

      expect(controller.flash[:notice]).to eq('Hello')
    end

    it 'does nothing when message is blank' do
      controller.send(:set_service_flash, :notice, nil)

      expect(controller.flash[:notice]).to be_nil
    end

    it 'does nothing when message is empty string' do
      controller.send(:set_service_flash, :notice, '')

      expect(controller.flash[:notice]).to be_nil
    end
  end

  describe '#resolve_path' do
    it 'returns string path as is' do
      expect(controller.send(:resolve_path, '/users')).to eq('/users')
    end

    it 'calls method for symbol path' do
      expect(controller.send(:resolve_path, :users_path)).to eq('/users')
    end
  end

  describe '#sanitize_json_result' do
    it 'removes internal keys' do
      result = {
        success: true,
        data: 'test',
        page_config: {},
        turbo_streams: [],
        redirect_to: '/path'
      }

      sanitized = controller.send(:sanitize_json_result, result)

      expect(sanitized).to eq({ success: true, data: 'test' })
    end
  end

  describe '#determine_error_status' do
    it 'returns :not_found for not_found error type' do
      expect(controller.send(:determine_error_status, { error_type: :not_found })).to eq(:not_found)
    end

    it 'returns :unauthorized for unauthorized error type' do
      expect(controller.send(:determine_error_status, { error_type: :unauthorized })).to eq(:unauthorized)
    end

    it 'returns :forbidden for forbidden error type' do
      expect(controller.send(:determine_error_status, { error_type: :forbidden })).to eq(:forbidden)
    end

    it 'returns :unprocessable_entity for validation error type' do
      expect(controller.send(:determine_error_status, { error_type: :validation })).to eq(:unprocessable_entity)
    end

    it 'returns :unprocessable_entity by default' do
      expect(controller.send(:determine_error_status, {})).to eq(:unprocessable_entity)
    end

    it 'uses explicit status from result' do
      expect(controller.send(:determine_error_status, { status: :bad_request })).to eq(:bad_request)
    end
  end

  describe '#resource_list_id' do
    it 'returns controller name with _list suffix' do
      expect(controller.send(:resource_list_id)).to eq('users_list')
    end
  end

  describe '#resource_partial_path' do
    it 'returns singularized partial path' do
      expect(controller.send(:resource_partial_path)).to eq('users/user')
    end
  end

  describe '#form_partial_path' do
    it 'returns form partial path' do
      expect(controller.send(:form_partial_path)).to eq('users/form')
    end
  end

  describe '#build_resource_streams' do
    let(:resource) do
      OpenStruct.new(id: 1).tap do |r|
        def r.class
          OpenStruct.new(name: 'User')
        end
      end
    end

    it 'builds prepend stream for create action' do
      result = { action: :create, resource: resource }
      streams = controller.send(:build_resource_streams, result)

      expect(streams.first[:action]).to eq(:prepend)
    end

    it 'builds replace stream for update action' do
      result = { action: :update, resource: resource }
      streams = controller.send(:build_resource_streams, result)

      expect(streams.first[:action]).to eq(:replace)
    end

    it 'builds remove stream for destroy action' do
      result = { action: :destroy, resource: resource }
      streams = controller.send(:build_resource_streams, result)

      expect(streams.first[:action]).to eq(:remove)
    end

    it 'returns empty array for unknown action' do
      result = { action: :unknown, resource: resource }
      streams = controller.send(:build_resource_streams, result)

      expect(streams).to eq([])
    end
  end

  describe '#handle_html_service_success with block' do
    it 'yields to block when given' do
      result = { success: true, message: 'Success!' }
      yielded = false

      controller.send(:handle_html_service_success, result, nil) do
        yielded = true
      end

      expect(yielded).to be true
    end
  end

  describe '#handle_turbo_service_success with block' do
    it 'yields to block when given' do
      result = { success: true }
      yielded = false

      controller.send(:handle_turbo_service_success, result) do
        yielded = true
      end

      expect(yielded).to be true
    end
  end

  describe '#handle_json_service_success with block' do
    it 'yields to block when given' do
      result = { success: true }
      yielded = false

      controller.send(:handle_json_service_success, result) do
        yielded = true
      end

      expect(yielded).to be true
    end
  end

  describe '#handle_html_service_error' do
    let(:result) { { success: false, error: 'Error' } }

    it 'yields to block when given' do
      yielded = false

      controller.send(:handle_html_service_error, result, nil) do
        yielded = true
      end

      expect(yielded).to be true
    end

    it 'redirects to redirect_to from result' do
      result[:redirect_to] = '/error-page'
      controller.send(:handle_html_service_error, result, nil)

      expect(controller.redirected_to[:path]).to eq('/error-page')
    end

    it 'redirects to failure_path when provided' do
      controller.send(:handle_html_service_error, result, '/failure')

      expect(controller.redirected_to[:path]).to eq('/failure')
    end

    it 'renders page_config with unprocessable_entity when present' do
      result[:page_config] = { type: :edit }
      controller.send(:handle_html_service_error, result, nil)

      expect(controller.rendered[:status]).to eq(:unprocessable_entity)
    end
  end

  describe '#handle_turbo_service_error' do
    let(:result) { { success: false, error: 'Error' } }

    it 'yields to block when given' do
      yielded = false

      controller.send(:handle_turbo_service_error, result) do
        yielded = true
      end

      expect(yielded).to be true
    end

    it 'renders turbo_streams from result when provided' do
      streams = [{ action: :remove, target: :item }]
      result[:turbo_streams] = streams
      controller.send(:handle_turbo_service_error, result)

      expect(controller.rendered[:turbo_stream]).to eq(streams)
    end
  end

  describe '#handle_json_service_error with block' do
    it 'yields to block when given' do
      result = { success: false, error: 'Error' }
      yielded = false

      controller.send(:handle_json_service_error, result) do
        yielded = true
      end

      expect(yielded).to be true
    end
  end

  describe '#render_turbo_success with resource' do
    let(:resource) do
      OpenStruct.new(id: 1).tap do |r|
        def r.class
          OpenStruct.new(name: 'User')
        end
      end
    end

    it 'includes resource streams for create action' do
      result = { action: :create, resource: resource }
      controller.send(:render_turbo_success, result)

      streams = controller.rendered[:turbo_stream]
      expect(streams.length).to be >= 2
    end
  end

  describe '#render_turbo_error' do
    let(:resource) do
      OpenStruct.new(id: 1, errors: ['Name is required']).tap do |r|
        def r.class
          OpenStruct.new(name: 'User')
        end

        def r.respond_to?(method, *)
          method == :errors || super
        end
      end
    end

    it 'includes form errors stream when errors present' do
      result = { errors: { name: ["can't be blank"] } }
      controller.send(:render_turbo_error, result)

      streams = controller.rendered[:turbo_stream]
      form_errors_stream = streams.find { |s| s[:target] == 'form_errors' }

      expect(form_errors_stream).to be_present
    end

    it 'includes form replacement when resource has errors' do
      result = { resource: resource }
      controller.send(:render_turbo_error, result)

      streams = controller.rendered[:turbo_stream]
      expect(streams.any? { |s| s[:action] == :replace }).to be true
    end
  end
end
