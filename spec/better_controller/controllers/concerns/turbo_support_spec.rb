# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Controllers::Concerns::TurboSupport do
  let(:controller_class) do
    Class.new do
      include BetterController::Controllers::Concerns::TurboSupport

      attr_accessor :request, :rendered

      def initialize
        @request = MockRequest.new
        @rendered = nil
      end

      def render(options = {})
        @rendered = options
      end

      def render_to_string(content)
        content.to_s
      end

      def redirect_to(path, options = {})
        { redirected_to: path, options: options }
      end

      def turbo_stream
        TurboStreamHelper.new
      end

      def helpers
        @helpers ||= Object.new.tap do |h|
          def h.dom_id(obj)
            "#{obj.class.name.downcase}_#{obj.id}"
          end
        end
      end
    end
  end

  # Mock request object
  class MockRequest
    attr_accessor :headers, :format, :user_agent

    def initialize
      @headers = {}
      @format = MockFormat.new
      @user_agent = nil
    end
  end

  # Mock format object
  class MockFormat
    attr_accessor :turbo_stream

    def initialize
      @turbo_stream = false
    end

    def turbo_stream?
      @turbo_stream
    end
  end

  # Mock turbo_stream helper
  class TurboStreamHelper
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

    def before(target, content = nil)
      { action: :before, target: target, content: content }
    end

    def after(target, content = nil)
      { action: :after, target: target, content: content }
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

  describe '#turbo_frame_request?' do
    it 'returns true when Turbo-Frame header is present' do
      controller.request.headers['Turbo-Frame'] = 'content'

      expect(controller.turbo_frame_request?).to be true
    end

    it 'returns false when Turbo-Frame header is absent' do
      expect(controller.turbo_frame_request?).to be false
    end
  end

  describe '#turbo_stream_request?' do
    it 'returns true when format is turbo_stream' do
      controller.request.format.turbo_stream = true

      expect(controller.turbo_stream_request?).to be true
    end

    it 'returns true when Accept header includes turbo-stream' do
      controller.request.headers['Accept'] = 'text/vnd.turbo-stream.html'

      expect(controller.turbo_stream_request?).to be true
    end

    it 'returns false for regular requests' do
      expect(controller.turbo_stream_request?).to be_falsey
    end
  end

  describe '#current_turbo_frame' do
    it 'returns the Turbo-Frame header value' do
      controller.request.headers['Turbo-Frame'] = 'users_content'

      expect(controller.current_turbo_frame).to eq('users_content')
    end

    it 'returns nil when no frame header' do
      expect(controller.current_turbo_frame).to be_nil
    end
  end

  describe '#turbo_native_app?' do
    it 'returns true when user agent includes Turbo Native' do
      controller.request.user_agent = 'Mozilla/5.0 Turbo Native iOS'

      expect(controller.turbo_native_app?).to be true
    end

    it 'returns false for regular browsers' do
      controller.request.user_agent = 'Mozilla/5.0 Chrome'

      expect(controller.turbo_native_app?).to be false
    end
  end

  describe '#build_stream' do
    it 'builds an append stream' do
      config = { action: :append, target: :users_list, partial: 'users/user' }

      stream = controller.build_stream(config)

      expect(stream[:action]).to eq(:append)
      expect(stream[:target]).to eq('users_list')
    end

    it 'builds a remove stream' do
      config = { action: :remove, target: :notification_1 }

      stream = controller.build_stream(config)

      expect(stream[:action]).to eq(:remove)
      expect(stream[:target]).to eq('notification_1')
    end

    it 'builds a refresh stream' do
      config = { action: :refresh }

      stream = controller.build_stream(config)

      expect(stream[:action]).to eq(:refresh)
    end
  end

  describe '#resolve_target' do
    it 'converts symbol to string' do
      expect(controller.resolve_target(:users_list)).to eq('users_list')
    end

    it 'keeps string as is' do
      expect(controller.resolve_target('users_list')).to eq('users_list')
    end

    it 'uses dom_id for objects' do
      obj = OpenStruct.new(id: 1)
      def obj.class
        OpenStruct.new(name: 'User')
      end

      target = controller.resolve_target(obj)

      expect(target).to include('user')
    end
  end

  describe '#stream_append' do
    it 'creates an append stream' do
      stream = controller.stream_append(:users_list, partial: 'users/user')

      expect(stream[:action]).to eq(:append)
    end
  end

  describe '#stream_prepend' do
    it 'creates a prepend stream' do
      stream = controller.stream_prepend(:users_list, partial: 'users/user')

      expect(stream[:action]).to eq(:prepend)
    end
  end

  describe '#stream_replace' do
    it 'creates a replace stream' do
      stream = controller.stream_replace(:user_1, partial: 'users/user')

      expect(stream[:action]).to eq(:replace)
    end
  end

  describe '#stream_update' do
    it 'creates an update stream' do
      stream = controller.stream_update(:counter, partial: 'shared/counter')

      expect(stream[:action]).to eq(:update)
    end
  end

  describe '#stream_remove' do
    it 'creates a remove stream' do
      stream = controller.stream_remove(:notification_1)

      expect(stream[:action]).to eq(:remove)
    end
  end

  describe '#stream_flash' do
    it 'creates a flash update stream' do
      stream = controller.stream_flash(type: :notice, message: 'Success!')

      expect(stream[:action]).to eq(:update)
      expect(stream[:target]).to eq('flash')
    end
  end

  describe '#stream_form_errors' do
    it 'creates a form errors update stream' do
      errors = { name: ["can't be blank"] }

      stream = controller.stream_form_errors(errors)

      expect(stream[:action]).to eq(:update)
      expect(stream[:target]).to eq('form_errors')
    end

    it 'accepts custom target' do
      stream = controller.stream_form_errors({}, target: :custom_errors)

      expect(stream[:target]).to eq('custom_errors')
    end
  end

  describe '#turbo_redirect_to' do
    it 'redirects with see_other status by default' do
      result = controller.turbo_redirect_to('/users')

      expect(result[:options][:status]).to eq(:see_other)
    end

    it 'accepts custom status' do
      result = controller.turbo_redirect_to('/users', status: :found)

      expect(result[:options][:status]).to eq(:found)
    end
  end

  describe '#render_streams' do
    it 'renders multiple streams' do
      streams = [
        { action: :update, target: :flash },
        { action: :remove, target: :item }
      ]

      controller.render_streams(streams)

      expect(controller.rendered[:turbo_stream]).to be_an(Array)
      expect(controller.rendered[:turbo_stream].length).to eq(2)
    end

    it 'accepts additional streams from block' do
      streams = [{ action: :update, target: :flash }]

      controller.render_streams(streams) do |additional|
        additional << { action: :remove, target: 'item' }
      end

      expect(controller.rendered[:turbo_stream].length).to eq(2)
    end
  end

  describe '#resolve_stream_content' do
    it 'returns html when specified' do
      config = { html: '<div>Hello</div>' }

      content = controller.send(:resolve_stream_content, config)

      expect(content).to eq('<div>Hello</div>')
    end

    it 'returns nil when nothing specified' do
      config = { action: :remove }

      content = controller.send(:resolve_stream_content, config)

      expect(content).to be_nil
    end

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

      it 'renders component' do
        config = { component: component_class, locals: {} }

        content = controller.send(:resolve_stream_content, config)

        expect(content).to be_present
      end
    end

    context 'with partial' do
      it 'renders partial' do
        allow(controller).to receive(:render_to_string)
          .with(partial: 'users/user', locals: { id: 1 })
          .and_return('<div>User</div>')

        config = { partial: 'users/user', locals: { id: 1 } }

        content = controller.send(:resolve_stream_content, config)

        expect(content).to eq('<div>User</div>')
      end
    end
  end

  describe '#build_stream_locals' do
    it 'duplicates base locals' do
      base = { key: 'value' }

      result = controller.send(:build_stream_locals, base)

      expect(result[:key]).to eq('value')
      expect(result).not_to be(base)
    end

    it 'adds result when present' do
      controller.instance_variable_set(:@result, { success: true })

      result = controller.send(:build_stream_locals, {})

      expect(result[:result]).to eq({ success: true })
    end

    it 'adds resource when present' do
      controller.instance_variable_set(:@resource, 'test_resource')

      result = controller.send(:build_stream_locals, {})

      expect(result[:resource]).to eq('test_resource')
    end

    it 'handles nil base locals' do
      result = controller.send(:build_stream_locals, nil)

      expect(result).to eq({})
    end
  end

  describe '#stream_before' do
    it 'creates a before stream' do
      stream = controller.stream_before(:user_1, partial: 'users/user')

      expect(stream[:action]).to eq(:before)
      expect(stream[:target]).to eq('user_1')
    end
  end

  describe '#stream_after' do
    it 'creates an after stream' do
      stream = controller.stream_after(:user_1, partial: 'users/user')

      expect(stream[:action]).to eq(:after)
      expect(stream[:target]).to eq('user_1')
    end
  end

  describe '#respond_with_turbo_stream' do
    context 'when turbo stream request' do
      before do
        controller.request.format.turbo_stream = true
      end

      it 'renders turbo streams' do
        controller.respond_with_turbo_stream do |streams|
          streams << { action: :update, target: 'flash' }
        end

        expect(controller.rendered[:turbo_stream]).to be_an(Array)
      end
    end

    context 'when not turbo stream request' do
      it 'yields the block' do
        called = false
        controller.respond_with_turbo_stream { called = true }

        expect(called).to be true
      end
    end
  end

  describe '#render_in_frame' do
    context 'when turbo frame request' do
      before do
        controller.request.headers['Turbo-Frame'] = 'content'
      end

      it 'sets layout to false by default' do
        controller.render_in_frame(template: 'users/show')

        expect(controller.rendered[:layout]).to be false
      end

      it 'respects explicit layout option' do
        controller.render_in_frame(template: 'users/show', layout: 'application')

        expect(controller.rendered[:layout]).to eq('application')
      end
    end

    context 'when not turbo frame request' do
      it 'renders normally' do
        controller.render_in_frame(template: 'users/show')

        expect(controller.rendered[:template]).to eq('users/show')
        expect(controller.rendered[:layout]).to be_nil
      end
    end
  end
end
