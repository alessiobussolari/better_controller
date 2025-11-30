# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Controllers::HtmlController do
  let(:controller_class) do
    Class.new do
      # Mock ActiveSupport::Concern behavior
      def self.included(base); end
      def self.helper_method(*methods); end

      include BetterController::Controllers::HtmlController

      attr_accessor :rendered

      def initialize
        @rendered = nil
        @page_config = nil
        @result = nil
      end

      def render(component_or_options = nil, extra_options = {}, **options)
        # Merge extra_options into options (for compatibility with Overrides#render signature)
        all_options = extra_options.merge(options)

        if component_or_options.is_a?(Hash)
          @rendered = component_or_options.merge(all_options)
        elsif component_or_options
          @rendered = { component: component_or_options, **all_options }
        else
          @rendered = all_options
        end
      end

      def render_to_string(content)
        content.to_s
      end
    end
  end

  let(:controller) { controller_class.new }

  describe '#page_config' do
    it 'returns @page_config' do
      controller.instance_variable_set(:@page_config, { type: :index })

      expect(controller.page_config).to eq({ type: :index })
    end

    it 'returns nil when not set' do
      expect(controller.page_config).to be_nil
    end
  end

  describe '#service_result' do
    it 'returns @result when set' do
      controller.instance_variable_set(:@result, { success: true })

      expect(controller.service_result).to eq({ success: true })
    end

    it 'returns @service_result as fallback' do
      controller.instance_variable_set(:@service_result, { success: true, data: 'test' })

      expect(controller.service_result).to eq({ success: true, data: 'test' })
    end

    it 'prefers @result over @service_result' do
      controller.instance_variable_set(:@result, { from: :result })
      controller.instance_variable_set(:@service_result, { from: :service_result })

      expect(controller.service_result).to eq({ from: :result })
    end
  end

  describe '#resource' do
    it 'returns resource from service_result' do
      resource = OpenStruct.new(id: 1, name: 'Test')
      controller.instance_variable_set(:@result, { success: true, resource: resource })

      expect(controller.resource).to eq(resource)
    end

    it 'memoizes the resource' do
      resource = OpenStruct.new(id: 1)
      controller.instance_variable_set(:@result, { success: true, resource: resource })

      controller.resource
      controller.instance_variable_set(:@result, { success: true, resource: OpenStruct.new(id: 2) })

      expect(controller.resource.id).to eq(1)
    end

    it 'returns nil when service_result is nil' do
      expect(controller.resource).to be_nil
    end
  end

  describe '#collection' do
    it 'returns collection from service_result' do
      collection = [1, 2, 3]
      controller.instance_variable_set(:@result, { success: true, collection: collection })

      expect(controller.collection).to eq(collection)
    end

    it 'memoizes the collection' do
      controller.instance_variable_set(:@result, { success: true, collection: [1, 2] })

      controller.collection
      controller.instance_variable_set(:@result, { success: true, collection: [3, 4, 5] })

      expect(controller.collection).to eq([1, 2])
    end
  end

  describe '#render_page_config' do
    let(:config) { { type: :index, title: 'Users' } }

    it 'sets @page_config' do
      controller.send(:render_page_config, config)

      expect(controller.instance_variable_get(:@page_config)).to eq(config)
    end

    it 'uses :ok status by default' do
      controller.send(:render_page_config, config)

      expect(controller.rendered[:status]).to eq(:ok)
    end

    it 'accepts custom status' do
      controller.send(:render_page_config, config, status: :unprocessable_entity)

      expect(controller.rendered[:status]).to eq(:unprocessable_entity)
    end

    context 'when component can be resolved' do
      before do
        # Create a mock component class
        stub_const('Templates::Index::PageComponent', Class.new do
          attr_reader :config
          def initialize(config:)
            @config = config
          end
        end)
      end

      it 'renders with resolved component' do
        controller.send(:render_page_config, config)

        expect(controller.rendered[:component]).to be_a(Templates::Index::PageComponent)
        expect(controller.rendered[:component].config).to eq(config)
      end
    end

    context 'when component cannot be resolved' do
      it 'renders with default options' do
        controller.send(:render_page_config, { type: :unknown_page })

        expect(controller.rendered[:component]).to be_nil
        expect(controller.rendered[:status]).to eq(:ok)
      end
    end
  end

  describe '#resolve_page_component' do
    it 'returns nil for non-hash config' do
      expect(controller.send(:resolve_page_component, 'string')).to be_nil
    end

    it 'returns nil when type is not present' do
      expect(controller.send(:resolve_page_component, {})).to be_nil
    end

    context 'with valid component' do
      before do
        stub_const('Templates::Show::PageComponent', Class.new)
      end

      it 'returns the component class' do
        component = controller.send(:resolve_page_component, { type: :show })

        expect(component).to eq(Templates::Show::PageComponent)
      end
    end

    context 'with non-existent component' do
      it 'returns nil' do
        expect(controller.send(:resolve_page_component, { type: :nonexistent })).to be_nil
      end
    end
  end

  describe '#page_component_class_name' do
    it 'builds correct class name' do
      class_name = controller.send(:page_component_class_name, :index)

      expect(class_name).to eq('Templates::Index::PageComponent')
    end

    it 'camelizes the page type' do
      class_name = controller.send(:page_component_class_name, :user_profile)

      expect(class_name).to eq('Templates::UserProfile::PageComponent')
    end
  end

  describe '#component_locals' do
    it 'includes page_config when set' do
      controller.instance_variable_set(:@page_config, { type: :index })

      expect(controller.send(:component_locals)[:page_config]).to eq({ type: :index })
    end

    it 'includes result when set' do
      controller.instance_variable_set(:@result, { success: true })

      expect(controller.send(:component_locals)[:result]).to eq({ success: true })
    end

    it 'includes resource when available' do
      resource = OpenStruct.new(id: 1)
      controller.instance_variable_set(:@result, { resource: resource })

      expect(controller.send(:component_locals)[:resource]).to eq(resource)
    end

    it 'includes collection when available' do
      controller.instance_variable_set(:@result, { collection: [1, 2, 3] })

      expect(controller.send(:component_locals)[:collection]).to eq([1, 2, 3])
    end

    it 'excludes nil values' do
      locals = controller.send(:component_locals)

      expect(locals).not_to have_key(:page_config)
      expect(locals).not_to have_key(:result)
    end
  end
end
