# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Rendering::ComponentRenderer do
  let(:controller_class) do
    Class.new do
      include BetterController::Rendering::ComponentRenderer

      attr_accessor :rendered, :page_config, :result

      def initialize
        @rendered = nil
        @page_config = nil
        @result = nil
        @current_user = nil
      end

      attr_accessor :current_user

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
        if content.respond_to?(:render_output)
          content.render_output
        elsif content.is_a?(String)
          content
        else
          "rendered:#{content.class.name}"
        end
      end
    end
  end

  # Mock ViewComponent class
  let(:component_class) do
    Class.new do
      attr_reader :locals

      def initialize(**locals)
        @locals = locals
      end

      def render_output
        "component_output:#{@locals.inspect}"
      end
    end
  end

  let(:controller) { controller_class.new }

  describe '#render_component' do
    it 'creates component with merged locals' do
      controller.render_component(component_class, locals: { title: 'Test' })

      expect(controller.rendered[:component]).to be_a(component_class)
    end

    it 'merges default locals with provided locals' do
      controller.instance_variable_set(:@page_config, { type: :index })
      controller.render_component(component_class, locals: { custom: 'value' })

      component = controller.rendered[:component]
      expect(component.locals).to include(:page_config, :custom)
    end

    it 'passes additional options to render' do
      controller.render_component(component_class, locals: {}, status: :ok)

      expect(controller.rendered[:status]).to eq(:ok)
    end

    context 'with to_string option' do
      it 'returns rendered string instead of rendering' do
        result = controller.render_component(component_class, locals: { test: true }, to_string: true)

        expect(result).to include('component_output')
        expect(controller.rendered).to be_nil
      end
    end
  end

  describe '#render_component_to_string' do
    it 'returns rendered component as string' do
      result = controller.render_component_to_string(component_class, locals: { name: 'Test' })

      expect(result).to include('component_output')
      expect(result).to include('name')
    end

    it 'includes default locals' do
      controller.instance_variable_set(:@result, { success: true })
      result = controller.render_component_to_string(component_class, locals: {})

      expect(result).to include('result')
    end
  end

  describe '#component_tag' do
    it 'returns component instance' do
      component = controller.component_tag(component_class, title: 'Test')

      expect(component).to be_a(component_class)
      expect(component.locals[:title]).to eq('Test')
    end

    it 'merges default locals' do
      user = OpenStruct.new(id: 1, name: 'User')
      controller.current_user = user

      component = controller.component_tag(component_class, custom: 'value')

      expect(component.locals[:current_user]).to eq(user)
      expect(component.locals[:custom]).to eq('value')
    end
  end

  describe '#render_component_collection' do
    let(:items) { [1, 2, 3] }

    let(:item_component_class) do
      Class.new do
        attr_reader :item

        def initialize(item:, **_rest)
          @item = item
        end

        def render_output
          "item:#{@item}"
        end
      end
    end

    it 'renders each item with the component' do
      result = controller.render_component_collection(items, item_component_class)

      expect(result).to include('item:1')
      expect(result).to include('item:2')
      expect(result).to include('item:3')
    end

    it 'uses custom item_key' do
      custom_component = Class.new do
        attr_reader :number

        def initialize(number:, **_rest)
          @number = number
        end

        def render_output
          "num:#{@number}"
        end
      end

      result = controller.render_component_collection([10, 20], custom_component, item_key: :number)

      expect(result).to include('num:10')
      expect(result).to include('num:20')
    end

    it 'passes additional options to each component' do
      extra_component = Class.new do
        attr_reader :item, :shared

        def initialize(item:, shared: nil, **_rest)
          @item = item
          @shared = shared
        end

        def render_output
          "#{@item}-#{@shared}"
        end
      end

      result = controller.render_component_collection([1, 2], extra_component, shared: 'common')

      expect(result).to include('1-common')
      expect(result).to include('2-common')
    end

    it 'returns html_safe string' do
      result = controller.render_component_collection(items, item_component_class)

      expect(result).to be_html_safe
    end
  end

  describe '#default_component_locals' do
    it 'includes current_user when available' do
      user = OpenStruct.new(id: 1)
      controller.current_user = user

      locals = controller.send(:default_component_locals)

      expect(locals[:current_user]).to eq(user)
    end

    it 'includes page_config when set' do
      controller.instance_variable_set(:@page_config, { type: :show })

      locals = controller.send(:default_component_locals)

      expect(locals[:page_config]).to eq({ type: :show })
    end

    it 'includes result when set' do
      controller.instance_variable_set(:@result, { success: true, data: 'test' })

      locals = controller.send(:default_component_locals)

      expect(locals[:result]).to eq({ success: true, data: 'test' })
    end

    it 'includes resource from result' do
      resource = OpenStruct.new(id: 1)
      controller.instance_variable_set(:@result, { resource: resource })

      locals = controller.send(:default_component_locals)

      expect(locals[:resource]).to eq(resource)
    end

    it 'includes collection from result' do
      collection = [1, 2, 3]
      controller.instance_variable_set(:@result, { collection: collection })

      locals = controller.send(:default_component_locals)

      expect(locals[:collection]).to eq(collection)
    end

    it 'does not include nil values' do
      locals = controller.send(:default_component_locals)

      expect(locals).not_to have_key(:page_config)
      expect(locals).not_to have_key(:result)
    end

    it 'handles non-hash result' do
      controller.instance_variable_set(:@result, 'string result')

      locals = controller.send(:default_component_locals)

      expect(locals[:result]).to eq('string result')
      expect(locals).not_to have_key(:resource)
      expect(locals).not_to have_key(:collection)
    end
  end

  describe '#view_component_available?' do
    context 'when ViewComponent is defined' do
      before do
        stub_const('ViewComponent::Base', Class.new)
      end

      it 'returns truthy' do
        expect(controller.send(:view_component_available?)).to be_truthy
      end
    end

    context 'when ViewComponent is not defined' do
      it 'returns falsey' do
        # ViewComponent::Base is not defined by default in tests
        hide_const('ViewComponent::Base') if defined?(ViewComponent::Base)
        expect(controller.send(:view_component_available?)).to be_falsey
      end
    end
  end
end
