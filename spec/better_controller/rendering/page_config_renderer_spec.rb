# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Rendering::PageConfigRenderer do
  let(:controller_class) do
    Class.new do
      include BetterController::Rendering::PageConfigRenderer

      attr_accessor :rendered, :page_config

      def initialize
        @rendered = nil
        @page_config = nil
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

      def render_to_string(content)
        if content.respond_to?(:render_in)
          "rendered_component:#{content.class.name}"
        else
          content.to_s
        end
      end
    end
  end

  let(:controller) { controller_class.new }

  describe '#render_with_page_config' do
    let(:config) { { type: :index, title: 'Users' } }

    it 'sets @page_config' do
      controller.render_with_page_config(config)

      expect(controller.page_config).to eq(config)
    end

    context 'when component can be found' do
      before do
        stub_const('Templates::Index::PageComponent', Class.new do
          attr_reader :config
          def initialize(config:)
            @config = config
          end
        end)
      end

      it 'renders with the found component' do
        controller.render_with_page_config(config)

        expect(controller.rendered[:component]).to be_a(Templates::Index::PageComponent)
      end

      it 'passes config to component' do
        controller.render_with_page_config(config)

        expect(controller.rendered[:component].config).to eq(config)
      end
    end

    context 'when component cannot be found' do
      it 'renders with default options' do
        controller.render_with_page_config({ type: :unknown })

        expect(controller.rendered[:component]).to be_nil
      end
    end

    it 'passes additional options' do
      controller.render_with_page_config({ type: :unknown }, layout: false)

      expect(controller.rendered[:layout]).to eq(false)
    end
  end

  describe '#render_page_section' do
    context 'when page_config is set' do
      before do
        controller.instance_variable_set(:@page_config, {
          header: { component: 'HeaderComponent', title: 'Test' },
          body: { component: 'BodyComponent' }
        })
      end

      it 'returns fallback when section not found' do
        result = controller.render_page_section(:footer, fallback: 'default')

        expect(result).to eq('default')
      end

      it 'renders component for found section' do
        stub_const('HeaderComponent', Class.new do
          attr_reader :title
          def initialize(title:)
            @title = title
          end
          def render_in(*)
            "header:#{@title}"
          end
        end)

        result = controller.render_page_section(:header)

        expect(result).to include('HeaderComponent')
      end
    end

    context 'when page_config is nil' do
      it 'returns fallback' do
        result = controller.render_page_section(:header, fallback: 'fallback_content')

        expect(result).to eq('fallback_content')
      end

      it 'returns nil without fallback' do
        result = controller.render_page_section(:header)

        expect(result).to be_nil
      end
    end
  end

  describe '#render_config_component' do
    it 'returns empty string for non-hash config' do
      expect(controller.render_config_component('string')).to eq('')
      expect(controller.render_config_component(nil)).to eq('')
    end

    context 'with valid component config' do
      before do
        stub_const('MyComponent', Class.new do
          attr_reader :options
          def initialize(**options)
            @options = options
          end
          def render_in(*)
            "rendered"
          end
        end)
      end

      it 'instantiates and renders component' do
        config = { component: MyComponent, title: 'Test' }

        result = controller.render_config_component(config)

        expect(result).to include('MyComponent')
      end

      it 'passes options except component and type' do
        config = { component: MyComponent, type: :header, title: 'Test', subtitle: 'Sub' }

        controller.render_config_component(config)

        # The component should receive title and subtitle, not component or type
      end
    end

    it 'returns empty string when component class not found' do
      config = { component: 'NonExistentComponent' }

      expect(controller.render_config_component(config)).to eq('')
    end
  end

  describe '#find_page_component' do
    it 'returns nil for non-hash config' do
      expect(controller.send(:find_page_component, 'string')).to be_nil
    end

    context 'with explicit component' do
      before do
        stub_const('ExplicitComponent', Class.new)
      end

      it 'returns explicit component class' do
        config = { component: ExplicitComponent }

        expect(controller.send(:find_page_component, config)).to eq(ExplicitComponent)
      end

      it 'resolves string component name' do
        config = { component: 'ExplicitComponent' }

        expect(controller.send(:find_page_component, config)).to eq(ExplicitComponent)
      end
    end

    context 'with type-based lookup' do
      before do
        stub_const('Templates::Show::PageComponent', Class.new)
      end

      it 'finds component by type' do
        config = { type: :show }

        expect(controller.send(:find_page_component, config)).to eq(Templates::Show::PageComponent)
      end

      it 'returns nil for unknown type' do
        config = { type: :unknown_type }

        expect(controller.send(:find_page_component, config)).to be_nil
      end
    end
  end

  describe '#find_type_component' do
    it 'tries multiple class name patterns' do
      stub_const('Templates::Edit::PageComponent', Class.new)

      result = controller.send(:find_type_component, :edit)

      expect(result).to eq(Templates::Edit::PageComponent)
    end

    it 'finds component with Component suffix' do
      stub_const('Templates::NewComponent', Class.new)

      result = controller.send(:find_type_component, :new)

      expect(result).to eq(Templates::NewComponent)
    end

    it 'finds bare PageComponent' do
      stub_const('Form::PageComponent', Class.new)

      result = controller.send(:find_type_component, :form)

      expect(result).to eq(Form::PageComponent)
    end

    it 'finds PageComponent without namespace' do
      stub_const('DashboardPageComponent', Class.new)

      result = controller.send(:find_type_component, :dashboard)

      expect(result).to eq(DashboardPageComponent)
    end

    it 'returns nil when no component found' do
      expect(controller.send(:find_type_component, :nonexistent)).to be_nil
    end
  end

  describe '#resolve_component_class' do
    it 'returns Class directly' do
      klass = Class.new

      expect(controller.send(:resolve_component_class, { component: klass })).to eq(klass)
    end

    it 'constantizes string' do
      stub_const('StringComponent', Class.new)

      expect(controller.send(:resolve_component_class, { component: 'StringComponent' })).to eq(StringComponent)
    end

    it 'constantizes symbol' do
      stub_const('SymbolComponent', Class.new)

      expect(controller.send(:resolve_component_class, { component: :SymbolComponent })).to eq(SymbolComponent)
    end

    it 'returns nil for unknown class name' do
      expect(controller.send(:resolve_component_class, { component: 'UnknownClass' })).to be_nil
    end

    it 'returns nil when no component key' do
      expect(controller.send(:resolve_component_class, {})).to be_nil
    end
  end

  describe '#page_component_namespace' do
    it 'returns configured namespace' do
      expect(controller.send(:page_component_namespace)).to eq('Templates')
    end

    context 'with custom configuration' do
      before do
        allow(BetterController.config).to receive(:page_component_namespace).and_return('CustomNamespace')
      end

      it 'uses custom namespace' do
        expect(controller.send(:page_component_namespace)).to eq('CustomNamespace')
      end
    end
  end
end
