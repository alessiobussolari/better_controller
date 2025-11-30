# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Errors::ServiceError do
  describe '#initialize' do
    it 'stores the resource' do
      resource = { id: 1 }
      error = described_class.new(resource, { success: false })

      expect(error.resource).to eq(resource)
    end

    it 'stores the meta' do
      meta = { success: false, message: 'Failed', status: :unprocessable_entity }
      error = described_class.new('resource', meta)

      expect(error.meta).to eq(meta)
    end

    it 'uses message from meta' do
      error = described_class.new('resource', { message: 'Custom error message' })

      expect(error.message).to eq('Custom error message')
    end

    it 'defaults to "Operation failed" when no message in meta' do
      error = described_class.new('resource', { success: false })

      expect(error.message).to eq('Operation failed')
    end

    it 'handles nil meta' do
      error = described_class.new('resource', nil)

      expect(error.meta).to eq({})
      expect(error.message).to eq('Operation failed')
    end
  end

  describe '#errors' do
    it 'returns errors hash when resource responds to errors' do
      resource = double('resource', errors: double(to_hash: { name: ['is required'] }))
      error = described_class.new(resource, { success: false })

      expect(error.errors).to eq({ name: ['is required'] })
    end

    it 'returns nil when resource does not respond to errors' do
      error = described_class.new('plain string', { success: false })

      expect(error.errors).to be_nil
    end
  end

  describe 'inheritance' do
    it 'is a StandardError' do
      error = described_class.new('resource', { success: false })

      expect(error).to be_a(StandardError)
    end

    it 'can be raised and caught' do
      expect do
        raise described_class.new('resource', { message: 'Test error' })
      end.to raise_error(described_class, 'Test error')
    end
  end
end
