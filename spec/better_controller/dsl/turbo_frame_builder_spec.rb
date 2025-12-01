# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Dsl::TurboFrameBuilder do
  let(:builder) { described_class.new }

  describe '#component' do
    it 'sets config with type :component and class' do
      mock_component = Class.new

      builder.component(mock_component)
      result = builder.build

      expect(result[:config][:type]).to eq(:component)
      expect(result[:config][:klass]).to eq(mock_component)
      expect(result[:config][:locals]).to eq({})
    end

    it 'accepts locals option' do
      mock_component = Class.new

      builder.component(mock_component, locals: { title: 'Test' })
      result = builder.build

      expect(result[:config][:locals]).to eq({ title: 'Test' })
    end
  end

  describe '#partial' do
    it 'sets config with type :partial and path' do
      builder.partial('users/list')
      result = builder.build

      expect(result[:config][:type]).to eq(:partial)
      expect(result[:config][:path]).to eq('users/list')
      expect(result[:config][:locals]).to eq({})
    end

    it 'accepts locals option' do
      builder.partial('users/list', locals: { users: [] })
      result = builder.build

      expect(result[:config][:locals]).to eq({ users: [] })
    end
  end

  describe '#render_page' do
    it 'sets config with type :page' do
      builder.render_page
      result = builder.build

      expect(result[:config][:type]).to eq(:page)
      expect(result[:config][:status]).to eq(:ok)
    end

    it 'accepts status option' do
      builder.render_page(status: :unprocessable_entity)
      result = builder.build

      expect(result[:config][:status]).to eq(:unprocessable_entity)
    end
  end

  describe '#layout' do
    it 'defaults to false when not set' do
      builder.component(Class.new)
      result = builder.build

      expect(result[:layout]).to eq(false)
    end

    it 'can be set to true' do
      builder.component(Class.new)
      builder.layout(true)
      result = builder.build

      expect(result[:layout]).to eq(true)
    end

    it 'can be explicitly set to false' do
      builder.component(Class.new)
      builder.layout(false)
      result = builder.build

      expect(result[:layout]).to eq(false)
    end
  end

  describe '#build' do
    it 'returns hash with config and layout' do
      builder.component(Class.new)
      result = builder.build

      expect(result).to have_key(:config)
      expect(result).to have_key(:layout)
    end

    it 'returns nil config when nothing is set' do
      result = builder.build

      expect(result[:config]).to be_nil
      expect(result[:layout]).to eq(false)
    end
  end

  describe 'DSL usage via instance_eval' do
    it 'works with instance_eval for component' do
      mock_component = Class.new

      builder.instance_eval do
        component mock_component, locals: { foo: 'bar' }
      end

      result = builder.build
      expect(result[:config][:type]).to eq(:component)
      expect(result[:config][:klass]).to eq(mock_component)
      expect(result[:config][:locals]).to eq({ foo: 'bar' })
    end

    it 'works with instance_eval for partial' do
      builder.instance_eval do
        partial 'shared/header', locals: { title: 'Hello' }
      end

      result = builder.build
      expect(result[:config][:type]).to eq(:partial)
      expect(result[:config][:path]).to eq('shared/header')
    end

    it 'works with instance_eval for render_page' do
      builder.instance_eval do
        render_page status: :created
      end

      result = builder.build
      expect(result[:config][:type]).to eq(:page)
      expect(result[:config][:status]).to eq(:created)
    end

    it 'works with instance_eval for layout override' do
      builder.instance_eval do
        component Class.new
        layout true
      end

      result = builder.build
      expect(result[:layout]).to eq(true)
    end
  end
end
