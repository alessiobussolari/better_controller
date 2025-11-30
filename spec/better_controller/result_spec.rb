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
end
