# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Services::Service do
  # Mock resource class that simulates ActiveRecord behavior
  let(:mock_resource) do
    Class.new do
      attr_accessor :id, :name, :user_id

      def self.name
        'MockResource'
      end

      def self.column_names
        %w[id name user_id]
      end

      def self.all
        [new(id: 1, name: 'Test 1'), new(id: 2, name: 'Test 2')]
      end

      def self.where(conditions)
        # Return self to chain
        self
      end

      def self.find(id)
        new(id: id.to_i, name: "Resource #{id}")
      end

      def initialize(attrs = {})
        attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
      end

      def save
        true
      end

      def update(attrs)
        attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
        true
      end

      def destroy
        true
      end
    end
  end

  # Service that uses the mock resource
  let(:test_service_class) do
    resource = mock_resource
    Class.new(described_class) do
      define_method(:resource_class) { resource }
    end
  end

  let(:service) { test_service_class.new }

  describe '#all' do
    it 'returns all resources' do
      result = service.all
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'accepts ancestry params' do
      result = service.all(user_id: 5)
      expect(result).to be_an(Array)
    end
  end

  describe '#find' do
    it 'finds a resource by id' do
      result = service.find({}, 1)
      expect(result.id).to eq(1)
    end

    it 'accepts ancestry params' do
      result = service.find({ user_id: 5 }, 1)
      expect(result.id).to eq(1)
    end
  end

  describe '#create' do
    it 'creates a new resource' do
      result = service.create({}, { name: 'New Resource' })
      expect(result.name).to eq('New Resource')
    end

    it 'merges ancestry params into attributes' do
      result = service.create({ user_id: 10 }, { name: 'New Resource' })
      expect(result.name).to eq('New Resource')
      expect(result.user_id).to eq(10)
    end
  end

  describe '#update' do
    it 'updates an existing resource' do
      result = service.update({}, 1, { name: 'Updated Name' })
      expect(result.name).to eq('Updated Name')
    end

    it 'merges ancestry params into attributes' do
      result = service.update({ user_id: 20 }, 1, { name: 'Updated' })
      expect(result.user_id).to eq(20)
    end
  end

  describe '#destroy' do
    it 'destroys a resource' do
      result = service.destroy({}, 1)
      expect(result.id).to eq(1)
    end
  end

  describe '#resource_class' do
    it 'raises NotImplementedError when not overridden' do
      base_service = described_class.new
      expect { base_service.send(:resource_class) }.to raise_error(NotImplementedError)
    end
  end

  describe '#resource_scope' do
    it 'returns resource class when no ancestry params' do
      result = service.send(:resource_scope, {})
      expect(result).to eq(mock_resource)
    end

    it 'applies where conditions for valid column names' do
      expect(mock_resource).to receive(:where).with(user_id: 5).and_return(mock_resource)
      service.send(:resource_scope, { user_id: 5 })
    end

    it 'ignores invalid column names' do
      expect(mock_resource).not_to receive(:where).with(hash_including(:invalid_column))
      service.send(:resource_scope, { invalid_column: 99 })
    end
  end

  describe '#prepare_attributes' do
    it 'returns duplicate of attributes' do
      attrs = { name: 'Test' }
      result = service.send(:prepare_attributes, attrs, {})
      expect(result).to eq(attrs)
      expect(result).not_to be(attrs)
    end

    it 'merges ancestry params for valid columns' do
      result = service.send(:prepare_attributes, { name: 'Test' }, { user_id: 5 })
      expect(result[:name]).to eq('Test')
      expect(result[:user_id]).to eq(5)
    end

    it 'ignores invalid column names in ancestry params' do
      result = service.send(:prepare_attributes, { name: 'Test' }, { invalid: 99 })
      expect(result[:name]).to eq('Test')
      expect(result[:invalid]).to be_nil
    end
  end

  # Test the ExampleService that extends Service
  describe ExampleService do
    let(:example_service) { ExampleService.new }
    let(:valid_attributes) { { name: 'Test Example', email: 'test@example.com' } }
    let(:invalid_attributes) { { name: '', email: 'invalid' } }

    describe '#model_class' do
      it 'returns ExampleModel' do
        expect(example_service.model_class).to eq(ExampleModel)
      end
    end

    describe '#permitted_attributes' do
      it 'returns permitted attributes array' do
        expect(example_service.permitted_attributes).to eq([:name, :email])
      end
    end

    describe '#list_query' do
      it 'returns a collection of models' do
        result = example_service.list_query
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
        expect(result.first).to be_a(ExampleModel)
      end
    end

    describe '#find_query' do
      it 'returns a model with the specified id' do
        result = example_service.find_query(2)
        expect(result).to be_a(ExampleModel)
        expect(result.id).to eq(2)
      end
    end

    describe '#create' do
      context 'with valid attributes' do
        it 'creates a new model' do
          result = example_service.create(valid_attributes)
          expect(result).to be_a(ExampleModel)
          expect(result.name).to eq('Test Example')
        end
      end

      context 'with invalid attributes' do
        it 'raises a validation error' do
          expect { example_service.create(invalid_attributes) }.to raise_error(ActiveModel::ValidationError)
        end
      end
    end

    describe '#update' do
      let(:resource) { ExampleModel.new(id: 1, name: 'Original', email: 'original@example.com') }

      context 'with valid attributes' do
        it 'updates the model' do
          result = example_service.update(resource, valid_attributes)
          expect(result.name).to eq('Test Example')
        end
      end

      context 'with invalid attributes' do
        it 'raises a validation error' do
          expect { example_service.update(resource, invalid_attributes) }.to raise_error(ActiveModel::ValidationError)
        end
      end
    end

    describe '#destroy' do
      it 'returns the resource' do
        resource = ExampleModel.new(id: 1, name: 'Test', email: 'test@example.com')
        expect(example_service.destroy(resource)).to eq(resource)
      end
    end
  end
end
