# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe 'ActionDsl Turbo Frame Auto-Layout' do
  let(:controller_class) do
    Class.new do
      include BetterController::Controllers::Concerns::ActionDsl

      attr_accessor :rendered, :params, :request, :format_type

      def initialize
        @rendered = {}
        @params = {}
        @request = OpenStruct.new(headers: {})
        @format_type = :html
      end

      def render(component_or_options = nil, **options)
        if component_or_options.is_a?(Hash)
          @rendered = component_or_options.merge(options)
        elsif component_or_options
          @rendered = { component: component_or_options, **options }
        else
          @rendered = options
        end
      end

      def render_to_string(**options)
        options.to_s
      end

      def controller_name
        'tests'
      end

      def respond_to
        yield(TurboFrameFormatResponder.new(self))
      end

      # Simulate turbo_frame_request? from TurboSupport
      def turbo_frame_request?
        @turbo_frame_request || false
      end

      def turbo_frame_request=(value)
        @turbo_frame_request = value
      end
    end
  end

  # Unique format responder for turbo frame tests to avoid constant collision
  class TurboFrameFormatResponder
    def initialize(controller)
      @controller = controller
    end

    def html
      yield if @controller.format_type == :html
    end

    def turbo_stream
      yield if @controller.format_type == :turbo_stream
    end

    def json
      yield if @controller.format_type == :json
    end

    def csv
      yield if @controller.format_type == :csv
    end

    def xml
      yield if @controller.format_type == :xml
    end
  end

  let(:controller) { controller_class.new }

  describe '#render_page_or_component' do
    context 'when turbo_frame_request? is true' do
      before do
        controller.turbo_frame_request = true
      end

      context 'with page_config present' do
        let(:page_config) { { type: :index, title: 'Users' } }

        before do
          controller.instance_variable_set(:@page_config, page_config)
        end

        it 'renders with layout: false' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered[:layout]).to eq(false)
        end

        it 'preserves the status option' do
          controller.send(:render_page_or_component, {}, status: :ok)

          expect(controller.rendered[:status]).to eq(:ok)
          expect(controller.rendered[:layout]).to eq(false)
        end

        it 'uses custom status when provided' do
          controller.send(:render_page_or_component, {}, status: :created)

          expect(controller.rendered[:status]).to eq(:created)
          expect(controller.rendered[:layout]).to eq(false)
        end
      end

      context 'with default render (no page_config or component)' do
        it 'renders with layout: false' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered[:layout]).to eq(false)
        end

        it 'includes status in render options' do
          controller.send(:render_page_or_component, {}, status: :ok)

          expect(controller.rendered[:status]).to eq(:ok)
          expect(controller.rendered[:layout]).to eq(false)
        end
      end

      context 'with component configured' do
        let(:component_class) do
          Class.new do
            attr_reader :locals

            def initialize(**locals)
              @locals = locals
            end
          end
        end

        let(:config) do
          {
            component: component_class,
            component_locals: { user: 'test' }
          }
        end

        it 'renders the component' do
          controller.send(:render_page_or_component, config)

          expect(controller.rendered[:component]).to be_a(component_class)
        end
      end
    end

    context 'when turbo_frame_request? is false' do
      before do
        controller.turbo_frame_request = false
      end

      context 'with page_config present' do
        let(:page_config) { { type: :index, title: 'Users' } }

        before do
          controller.instance_variable_set(:@page_config, page_config)
        end

        it 'does not include layout option' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered).not_to have_key(:layout)
        end

        it 'renders with status only' do
          controller.send(:render_page_or_component, {}, status: :ok)

          expect(controller.rendered[:status]).to eq(:ok)
          expect(controller.rendered).not_to have_key(:layout)
        end
      end

      context 'with default render' do
        it 'does not include layout option' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered).not_to have_key(:layout)
        end
      end
    end

    context 'when turbo_frame_request? method does not exist' do
      let(:controller_without_turbo) do
        Class.new do
          include BetterController::Controllers::Concerns::ActionDsl

          attr_accessor :rendered, :params

          def initialize
            @rendered = {}
            @params = {}
          end

          def render(**options)
            @rendered = options
          end

          def render_to_string(**options)
            options.to_s
          end

          def controller_name
            'tests'
          end

          def respond_to
            yield(OpenStruct.new(html: -> { yield }))
          end
        end.new
      end

      it 'does not fail and renders without layout option' do
        controller_without_turbo.send(:render_page_or_component, {})

        expect(controller_without_turbo.rendered).not_to have_key(:layout)
      end
    end
  end

  describe '#render_page_config with layout parameter' do
    let(:page_config) { { type: :show, title: 'User Details' } }

    it 'accepts layout parameter and passes it to render' do
      controller.send(:render_page_config, page_config, status: :ok, layout: false)

      expect(controller.rendered[:layout]).to eq(false)
      expect(controller.rendered[:status]).to eq(:ok)
    end

    it 'does not include layout when nil' do
      controller.send(:render_page_config, page_config, status: :ok, layout: nil)

      expect(controller.rendered).not_to have_key(:layout)
      expect(controller.rendered[:status]).to eq(:ok)
    end

    it 'sets @page_config instance variable' do
      controller.send(:render_page_config, page_config)

      expect(controller.instance_variable_get(:@page_config)).to eq(page_config)
    end
  end

  describe 'integration: action execution with Turbo Frame' do
    # Use a local service class to avoid polluting global ExampleService
    let(:turbo_test_service) do
      Class.new do
        def self.call(params: {})
          { success: true, page_config: { type: :index, items: [] } }
        end
      end
    end

    before do
      service = turbo_test_service
      controller_class.action(:turbo_index) do
        service service
      end
    end

    context 'when request is a Turbo Frame request' do
      before do
        controller.turbo_frame_request = true
        controller.format_type = :html
      end

      it 'auto-disables layout in the rendered response' do
        controller.send(:execute_registered_action, :turbo_index)

        expect(controller.rendered[:layout]).to eq(false)
      end
    end

    context 'when request is a normal HTML request' do
      before do
        controller.turbo_frame_request = false
        controller.format_type = :html
      end

      it 'does not set layout option' do
        controller.send(:execute_registered_action, :turbo_index)

        expect(controller.rendered).not_to have_key(:layout)
      end
    end
  end
end
