# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Services::Service do
  let(:service) { ExampleService.new }
  let(:valid_attributes) { { name: 'Test Example', email: 'test@example.com' } }
  let(:invalid_attributes) { { name: '', email: 'invalid' } }

  describe '#model_class' do
    it 'returns the model class' do
      expect(service.model_class).to eq(ExampleModel)
    end
  end

  describe '#permitted_attributes' do
    it 'returns the permitted attributes' do
      expect(service.permitted_attributes).to eq([:name, :email])
    end
  end

  describe '#list_query' do
    it 'returns a collection of models' do
      result = service.list_query
      
      expect(result).to be_an(Array)
      expect(result.length).to eq(3)
      expect(result.first).to be_a(ExampleModel)
      expect(result.first.name).to eq('Example 1')
    end
  end

  describe '#find_query' do
    it 'returns a model with the specified id' do
      result = service.find_query(2)
      
      expect(result).to be_a(ExampleModel)
      expect(result.id).to eq(2)
      expect(result.name).to eq('Example 2')
    end
  end

  describe '#create' do
    context 'with valid attributes' do
      it 'creates a new model' do
        result = service.create(valid_attributes)
        
        expect(result).to be_a(ExampleModel)
        expect(result.name).to eq('Test Example')
        expect(result.email).to eq('test@example.com')
      end
    end

    context 'with invalid attributes' do
      it 'raises a validation error' do
        expect {
          service.create(invalid_attributes)
        }.to raise_error(ActiveModel::ValidationError)
      end
    end
  end

  describe '#update' do
    let(:resource) { ExampleModel.new(id: 1, name: 'Original', email: 'original@example.com') }

    context 'with valid attributes' do
      it 'updates the model' do
        result = service.update(resource, valid_attributes)
        
        expect(result).to be_a(ExampleModel)
        expect(result.name).to eq('Test Example')
        expect(result.email).to eq('test@example.com')
      end
    end

    context 'with invalid attributes' do
      it 'raises a validation error' do
        expect {
          service.update(resource, invalid_attributes)
        }.to raise_error(ActiveModel::ValidationError)
      end
    end
  end

  describe '#destroy' do
    let(:resource) { ExampleModel.new(id: 1, name: 'Example', email: 'example@example.com') }

    it 'returns the destroyed resource' do
      result = service.destroy(resource)
      
      expect(result).to eq(resource)
    end
  end
end
