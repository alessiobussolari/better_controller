# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe 'ActionDsl Turbo Frame Rendering' do
  # Mock ViewComponent class for testing
  let(:mock_view_component) do
    Class.new do
      attr_reader :config

      def initialize(config:)
        @config = config
      end
    end
  end

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
    describe 'with Turbo Frame request and page with klass' do
      before do
        controller.turbo_frame_request = true
      end

      context 'when page has a klass (ViewComponent class)' do
        let(:inner_mock_view_component) do
          Class.new do
            attr_reader :config

            def initialize(config:)
              @config = config
            end
          end
        end

        let(:page_config) do
          # Simulate BetterPage::Config behavior with klass
          component_class = inner_mock_view_component
          config = { type: :index, title: 'Users' }
          config.define_singleton_method(:klass) { component_class }
          config.define_singleton_method(:respond_to?) do |method, *|
            method == :klass || super(method)
          end
          config
        end

        before do
          controller.instance_variable_set(:@page_config, page_config)
        end

        it 'renders the ViewComponent with layout: false' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered[:component]).to be_a(inner_mock_view_component)
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

      context 'when page has [:klass] (Hash with klass key)' do
        let(:mock_view_component) do
          Class.new do
            attr_reader :config

            def initialize(config:)
              @config = config
            end
          end
        end

        let(:page_config) { { type: :index, klass: mock_view_component } }

        before do
          controller.instance_variable_set(:@page_config, page_config)
        end

        it 'renders the ViewComponent with layout: false' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered[:component]).to be_a(mock_view_component)
          expect(controller.rendered[:layout]).to eq(false)
        end
      end

      context 'when page does not have klass (no ViewComponent)' do
        let(:page_config) { { type: :index, title: 'Users' } }

        before do
          controller.instance_variable_set(:@page_config, page_config)
        end

        it 'renders with Rails standard render' do
          controller.send(:render_page_or_component, {})

          # No component rendered, just status
          expect(controller.rendered[:component]).to be_nil
          expect(controller.rendered[:status]).to eq(:ok)
        end

        it 'does not specify layout option' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered).not_to have_key(:layout)
        end
      end

      context 'with no page_config at all' do
        it 'renders with Rails standard render' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered[:status]).to eq(:ok)
          expect(controller.rendered).not_to have_key(:layout)
        end
      end
    end

    describe 'with non-Turbo Frame request' do
      before do
        controller.turbo_frame_request = false
      end

      context 'with page_config present (with klass)' do
        let(:mock_view_component) do
          Class.new do
            attr_reader :config

            def initialize(config:)
              @config = config
            end
          end
        end

        let(:page_config) { { type: :index, klass: mock_view_component } }

        before do
          controller.instance_variable_set(:@page_config, page_config)
        end

        it 'renders with Rails standard render (ignores klass)' do
          controller.send(:render_page_or_component, {})

          # No component rendered for non-turbo-frame
          expect(controller.rendered[:component]).to be_nil
          expect(controller.rendered[:status]).to eq(:ok)
        end

        it 'does not specify layout option' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered).not_to have_key(:layout)
        end
      end

      context 'with default render' do
        it 'renders with Rails standard render' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered[:status]).to eq(:ok)
        end

        it 'does not specify layout option' do
          controller.send(:render_page_or_component, {})

          expect(controller.rendered).not_to have_key(:layout)
        end
      end
    end

    describe 'when turbo_frame_request? method does not exist' do
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

      it 'does not fail and renders with Rails standard render' do
        controller_without_turbo.send(:render_page_or_component, {})

        expect(controller_without_turbo.rendered[:status]).to eq(:ok)
        expect(controller_without_turbo.rendered).not_to have_key(:layout)
      end
    end
  end

  describe '#page_has_component?' do
    context 'when page responds to :klass method' do
      it 'returns true if klass is present' do
        page = Object.new
        page.define_singleton_method(:klass) { String }

        expect(controller.send(:page_has_component?, page)).to be true
      end

      it 'returns false if klass is nil' do
        page = Object.new
        page.define_singleton_method(:klass) { nil }

        expect(controller.send(:page_has_component?, page)).to be false
      end
    end

    context 'when page is a Hash' do
      it 'returns true if [:klass] is present' do
        page = { klass: String }

        expect(controller.send(:page_has_component?, page)).to be true
      end

      it 'returns false if [:klass] is nil' do
        page = { klass: nil }

        expect(controller.send(:page_has_component?, page)).to be false
      end

      it 'returns false if [:klass] key does not exist' do
        page = { type: :index }

        expect(controller.send(:page_has_component?, page)).to be false
      end
    end

    context 'when page is nil' do
      it 'returns false' do
        expect(controller.send(:page_has_component?, nil)).to be false
      end
    end
  end

  describe '#render_turbo_frame_component' do
    let(:mock_view_component) do
      Class.new do
        attr_reader :config

        def initialize(config:)
          @config = config
        end
      end
    end

    context 'when page responds to :klass method' do
      let(:inner_mock_component) do
        Class.new do
          attr_reader :config

          def initialize(config:)
            @config = config
          end
        end
      end

      let(:page) do
        component_class = inner_mock_component
        obj = { type: :index }
        obj.define_singleton_method(:klass) { component_class }
        obj
      end

      it 'instantiates the ViewComponent with config: page' do
        controller.send(:render_turbo_frame_component, page)

        component = controller.rendered[:component]
        expect(component).to be_a(inner_mock_component)
        expect(component.config).to eq(page)
      end

      it 'renders with layout: false' do
        controller.send(:render_turbo_frame_component, page)

        expect(controller.rendered[:layout]).to eq(false)
      end

      it 'includes status in render options' do
        controller.send(:render_turbo_frame_component, page, status: :created)

        expect(controller.rendered[:status]).to eq(:created)
      end
    end

    context 'when page is a Hash with [:klass]' do
      let(:page) { { type: :index, klass: mock_view_component } }

      it 'instantiates the ViewComponent with config: page' do
        controller.send(:render_turbo_frame_component, page)

        component = controller.rendered[:component]
        expect(component).to be_a(mock_view_component)
        expect(component.config).to eq(page)
      end

      it 'renders with layout: false' do
        controller.send(:render_turbo_frame_component, page)

        expect(controller.rendered[:layout]).to eq(false)
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
    let(:mock_view_component) do
      Class.new do
        attr_reader :config

        def initialize(config:)
          @config = config
        end
      end
    end

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

    context 'when request is a Turbo Frame request (no klass in result)' do
      before do
        controller.turbo_frame_request = true
        controller.format_type = :html
      end

      it 'renders with Rails standard render (no layout specified)' do
        controller.send(:execute_registered_action, :turbo_index)

        # No klass in page_config, so standard render
        expect(controller.rendered).not_to have_key(:layout)
        expect(controller.rendered[:status]).to eq(:ok)
      end
    end

    context 'when request is a normal HTML request' do
      before do
        controller.turbo_frame_request = false
        controller.format_type = :html
      end

      it 'renders with Rails standard render (no layout specified)' do
        controller.send(:execute_registered_action, :turbo_index)

        expect(controller.rendered).not_to have_key(:layout)
        expect(controller.rendered[:status]).to eq(:ok)
      end
    end
  end
end
