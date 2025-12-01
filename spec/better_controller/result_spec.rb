# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Result do
  describe '#initialize' do
    it 'stores the resource' do
      resource = { id: 1, name: 'Test' }
      result = described_class.new(resource)

      expect(result.resource).to eq(resource)
    end

    it 'stores meta with success defaulting to true' do
      result = described_class.new('resource')

      expect(result.meta).to eq({ success: true })
    end

    it 'allows custom meta' do
      result = described_class.new('resource', meta: { message: 'Created', success: true })

      expect(result.meta).to eq({ message: 'Created', success: true })
    end

    it 'preserves success: false in meta' do
      result = described_class.new('resource', meta: { success: false, message: 'Failed' })

      expect(result.meta[:success]).to be false
      expect(result.meta[:message]).to eq('Failed')
    end

    it 'handles non-hash meta by defaulting to success: true' do
      result = described_class.new('resource', meta: 'invalid')

      expect(result.meta).to eq({ success: true })
    end
  end

  describe '#success?' do
    it 'returns true when meta[:success] is true' do
      result = described_class.new('resource', meta: { success: true })

      expect(result.success?).to be true
    end

    it 'returns false when meta[:success] is false' do
      result = described_class.new('resource', meta: { success: false })

      expect(result.success?).to be false
    end

    it 'returns true by default' do
      result = described_class.new('resource')

      expect(result.success?).to be true
    end
  end

  describe '#failure?' do
    it 'returns false when successful' do
      result = described_class.new('resource', meta: { success: true })

      expect(result.failure?).to be false
    end

    it 'returns true when failed' do
      result = described_class.new('resource', meta: { success: false })

      expect(result.failure?).to be true
    end
  end

  describe '#message' do
    it 'returns the message from meta' do
      result = described_class.new('resource', meta: { message: 'Operation successful' })

      expect(result.message).to eq('Operation successful')
    end

    it 'returns nil when no message' do
      result = described_class.new('resource')

      expect(result.message).to be_nil
    end
  end

  describe '#errors' do
    it 'returns errors from resource if resource responds to errors' do
      resource = double('resource', errors: { name: ['is required'] })
      result = described_class.new(resource)

      expect(result.errors).to eq({ name: ['is required'] })
    end

    it 'returns nil if resource does not respond to errors' do
      result = described_class.new('plain string')

      expect(result.errors).to be_nil
    end
  end

  describe '#dig' do
    it 'returns resource for :resource key' do
      resource = { id: 1, name: 'Test' }
      result = described_class.new(resource)

      expect(result.dig(:resource)).to eq(resource)
    end

    it 'returns nil for non-existent key' do
      result = described_class.new('resource')

      expect(result.dig(:nonexistent)).to be_nil
    end

    it 'supports nested dig on meta' do
      result = described_class.new('resource', meta: { nested: { key: 'value' } })

      expect(result.dig(:meta, :nested, :key)).to eq('value')
    end

    it 'returns collection for :collection key when resource is enumerable' do
      collection = [1, 2, 3]
      result = described_class.new(collection)

      expect(result.dig(:collection)).to eq(collection)
    end

    it 'returns nil for :collection key when resource is a Hash' do
      resource = { id: 1 }
      result = described_class.new(resource)

      expect(result.dig(:collection)).to be_nil
    end

    it 'returns error from meta' do
      result = described_class.new('resource', meta: { error: 'Something went wrong' })

      expect(result.dig(:error)).to eq('Something went wrong')
    end

    it 'returns error_type from meta' do
      result = described_class.new('resource', meta: { error_type: :validation_error })

      expect(result.dig(:error_type)).to eq(:validation_error)
    end

    it 'returns page_config from meta' do
      page_config = { page: 1, per_page: 25 }
      result = described_class.new('resource', meta: { page_config: page_config })

      expect(result.dig(:page_config)).to eq(page_config)
    end
  end

  describe '#[]' do
    it 'returns resource value' do
      resource = { id: 1 }
      result = described_class.new(resource)

      expect(result[:resource]).to eq(resource)
    end

    it 'returns success status' do
      result = described_class.new('resource')

      expect(result[:success]).to be true
    end

    it 'returns meta hash' do
      result = described_class.new('resource', meta: { custom: 'value' })

      expect(result[:meta]).to include(custom: 'value')
    end

    it 'returns message' do
      result = described_class.new('resource', meta: { message: 'Done' })

      expect(result[:message]).to eq('Done')
    end
  end

  describe '#to_h' do
    it 'returns hash with resource' do
      resource = { id: 1 }
      result = described_class.new(resource)

      expect(result.to_h[:resource]).to eq(resource)
    end

    it 'returns hash with success status' do
      result = described_class.new('resource')

      expect(result.to_h[:success]).to be true
    end

    it 'returns hash with meta' do
      result = described_class.new('resource', meta: { custom: 'data' })

      expect(result.to_h[:meta]).to include(custom: 'data')
    end

    it 'includes collection when resource is enumerable' do
      collection = [1, 2, 3]
      result = described_class.new(collection)

      expect(result.to_h[:collection]).to eq(collection)
    end

    it 'excludes collection when resource is a Hash' do
      resource = { id: 1 }
      result = described_class.new(resource)

      expect(result.to_h).not_to have_key(:collection)
    end

    it 'includes error from meta' do
      result = described_class.new('resource', meta: { error: 'Failed' })

      expect(result.to_h[:error]).to eq('Failed')
    end

    it 'includes error_type from meta' do
      result = described_class.new('resource', meta: { error_type: :not_found })

      expect(result.to_h[:error_type]).to eq(:not_found)
    end

    it 'includes page_config from meta' do
      page_config = { total: 100 }
      result = described_class.new('resource', meta: { page_config: page_config })

      expect(result.to_h[:page_config]).to eq(page_config)
    end

    it 'compacts nil values' do
      result = described_class.new('resource')

      # message is nil, so it should not be in the hash
      expect(result.to_h).not_to have_key(:message)
      expect(result.to_h).not_to have_key(:errors)
      expect(result.to_h).not_to have_key(:error)
      expect(result.to_h).not_to have_key(:error_type)
      expect(result.to_h).not_to have_key(:page_config)
    end

    it 'includes errors when resource has errors' do
      resource = double('resource', errors: { name: ['is required'] })
      result = described_class.new(resource)

      expect(result.to_h[:errors]).to eq({ name: ['is required'] })
    end
  end
end
