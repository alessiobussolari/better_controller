# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Configuration do
  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  describe '.options' do
    it 'returns default options' do
      expect(described_class.options).to be_a(Hash)
      expect(described_class.options[:pagination]).to be_present
    end
  end

  describe '.pagination' do
    it 'returns pagination configuration' do
      expect(described_class.pagination[:enabled]).to be true
      expect(described_class.pagination[:per_page]).to eq(25)
    end
  end

  describe '.serialization' do
    it 'returns serialization configuration' do
      expect(described_class.serialization[:include_root]).to be false
      expect(described_class.serialization[:camelize_keys]).to be true
    end
  end

  describe '.error_handling' do
    it 'returns error handling configuration' do
      expect(described_class.error_handling[:log_errors]).to be true
      expect(described_class.error_handling[:detailed_errors]).to be true
    end
  end

  describe '.html' do
    it 'returns HTML configuration' do
      expect(described_class.html[:page_component_namespace]).to eq('Templates')
      expect(described_class.html[:flash_partial]).to eq('shared/flash')
      expect(described_class.html[:form_errors_partial]).to eq('shared/form_errors')
    end
  end

  describe '.turbo' do
    it 'returns Turbo configuration' do
      expect(described_class.turbo[:enabled]).to be true
      expect(described_class.turbo[:auto_flash]).to be true
      expect(described_class.turbo[:auto_form_errors]).to be true
    end
  end

  describe '.page_component_namespace' do
    it 'returns the page component namespace' do
      expect(described_class.page_component_namespace).to eq('Templates')
    end
  end

  describe '.flash_partial' do
    it 'returns the flash partial path' do
      expect(described_class.flash_partial).to eq('shared/flash')
    end
  end

  describe '.form_errors_partial' do
    it 'returns the form errors partial path' do
      expect(described_class.form_errors_partial).to eq('shared/form_errors')
    end
  end

  describe '.turbo_enabled?' do
    it 'returns whether turbo is enabled' do
      expect(described_class.turbo_enabled?).to be true
    end
  end

  describe '.configure' do
    it 'allows modifying configuration' do
      described_class.configure do |config|
        config[:html][:page_component_namespace] = 'Components'
      end

      expect(described_class.page_component_namespace).to eq('Components')
    end
  end

  describe '.reset!' do
    it 'resets configuration to defaults' do
      described_class.configure do |config|
        config[:html][:page_component_namespace] = 'Custom'
      end

      described_class.reset!

      expect(described_class.page_component_namespace).to eq('Templates')
    end
  end

  describe '[] accessor' do
    it 'allows accessing options by key' do
      expect(described_class[:pagination]).to be_a(Hash)
      expect(described_class[:html]).to be_a(Hash)
    end
  end

  describe '[]= accessor' do
    it 'allows setting options by key' do
      described_class[:custom] = { value: 'test' }

      expect(described_class[:custom]).to eq({ value: 'test' })
    end
  end
end
