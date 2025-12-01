# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Config do
  let(:components) do
    {
      header: { title: 'Users', breadcrumbs: [{ label: 'Home' }] },
      table: { items: [1, 2, 3], columns: [:id, :name] },
      statistics: { total: 100 }
    }
  end

  let(:meta) { { page_type: :index, klass: 'IndexComponent' } }
  let(:config) { described_class.new(components, meta: meta) }

  describe '#initialize' do
    it 'stores components' do
      expect(config.components).to eq(components)
    end

    it 'stores meta' do
      expect(config.meta).to eq(meta)
    end

    it 'handles non-hash components' do
      config = described_class.new('invalid')
      expect(config.components).to eq({})
    end

    it 'handles non-hash meta' do
      config = described_class.new({}, meta: 'invalid')
      expect(config.meta).to eq({})
    end

    it 'defaults meta to empty hash' do
      config = described_class.new(components)
      expect(config.meta).to eq({})
    end
  end

  describe '#to_ary (destructuring)' do
    it 'supports destructuring' do
      comps, m = config
      expect(comps).to eq(components)
      expect(m).to eq(meta)
    end
  end

  describe '#[]' do
    it 'accesses components by key' do
      expect(config[:header]).to eq({ title: 'Users', breadcrumbs: [{ label: 'Home' }] })
    end

    it 'accesses meta values' do
      expect(config[:page_type]).to eq(:index)
    end

    it 'returns nil for non-existent key' do
      expect(config[:nonexistent]).to be_nil
    end
  end

  describe '#dig' do
    it 'digs into nested components' do
      expect(config.dig(:header, :title)).to eq('Users')
    end

    it 'digs into deeply nested values' do
      expect(config.dig(:header, :breadcrumbs, 0, :label)).to eq('Home')
    end

    it 'returns nil for non-existent path' do
      expect(config.dig(:header, :nonexistent, :key)).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns hash with components merged' do
      hash = config.to_h
      expect(hash[:header]).to eq(components[:header])
      expect(hash[:table]).to eq(components[:table])
    end

    it 'includes meta values' do
      hash = config.to_h
      expect(hash[:page_type]).to eq(:index)
      expect(hash[:klass]).to eq('IndexComponent')
    end

    it 'includes components and meta keys' do
      hash = config.to_h
      expect(hash[:components]).to eq(components)
      expect(hash[:meta]).to eq(meta)
    end
  end

  describe 'method_missing (direct component access)' do
    it 'accesses components as methods' do
      expect(config.header).to eq({ title: 'Users', breadcrumbs: [{ label: 'Home' }] })
    end

    it 'allows chained access' do
      expect(config.header[:title]).to eq('Users')
    end

    it 'raises NoMethodError for non-existent components' do
      expect { config.nonexistent_method }.to raise_error(NoMethodError)
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for existing components' do
      expect(config.respond_to?(:header)).to be true
    end

    it 'returns false for non-existent components' do
      expect(config.respond_to?(:nonexistent)).to be false
    end
  end

  describe '#component?' do
    it 'returns true for existing component' do
      expect(config.component?(:header)).to be true
    end

    it 'returns false for non-existent component' do
      expect(config.component?(:pagination)).to be false
    end

    it 'returns false for empty component' do
      config_with_empty = described_class.new({ header: {} })
      expect(config_with_empty.component?(:header)).to be false
    end
  end

  describe '#component_names' do
    it 'returns list of component names' do
      expect(config.component_names).to eq([:header, :table, :statistics])
    end
  end

  describe '#each_component' do
    it 'iterates over components' do
      names = []
      config.each_component { |name, _| names << name }
      expect(names).to eq([:header, :table, :statistics])
    end
  end

  describe '#present_components' do
    it 'returns only components with present values' do
      config_with_empty = described_class.new({
                                                header: { title: 'Test' },
                                                empty: {},
                                                nil_value: nil
                                              })
      expect(config_with_empty.present_components.keys).to eq([:header])
    end
  end

  describe '#page_type' do
    it 'returns page_type from meta' do
      expect(config.page_type).to eq(:index)
    end

    it 'returns nil when not set' do
      config = described_class.new({})
      expect(config.page_type).to be_nil
    end
  end

  describe '#klass' do
    it 'returns klass from meta' do
      expect(config.klass).to eq('IndexComponent')
    end

    it 'returns nil when not set' do
      config = described_class.new({})
      expect(config.klass).to be_nil
    end
  end
end
