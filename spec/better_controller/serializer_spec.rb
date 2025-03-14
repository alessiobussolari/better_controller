# frozen_string_literal: true

require 'spec_helper'

# Make sure our test class is properly defined
class TestSerializer
  include BetterController::Serializer
  
  attributes :id, :name, :email
  methods :full_name
  
  def full_name
    "#{object.name} (#{object.email})"
  end
  
  # Add the object accessor for the test
  attr_accessor :object
  
  def initialize(object = nil)
    @object = object
  end
end

RSpec.describe BetterController::Serializer do
  let(:example) { ExampleModel.new(id: 1, name: 'Test Example', email: 'test@example.com') }
  let(:serializer) { TestSerializer.new(example) }
  let(:collection) { [example, ExampleModel.new(id: 2, name: 'Example 2', email: 'example2@example.com')] }

  describe '.attributes' do
    it 'defines attributes to be serialized' do
      expect(TestSerializer.attributes).to include(:id, :name, :email)
    end
  end

  describe '.methods' do
    it 'defines methods to be included in serialization' do
      expect(TestSerializer.methods).to include(:full_name)
    end
  end

  describe '#serialize_resource' do
    it 'serializes a single resource' do
      result = serializer.serialize_resource(example, {})
      
      expect(result).to include(id: 1, name: 'Test Example', email: 'test@example.com')
      expect(result).to have_key(:full_name)
      expect(result[:full_name]).to eq('Test Example (test@example.com)')
    end
  end

  describe '#serialize_collection' do
    it 'serializes a collection of objects' do
      result = serializer.serialize_collection(collection, {})
      
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to include(id: 1, name: 'Test Example')
      expect(result.last).to include(id: 2, name: 'Example 2')
    end
  end

  describe '#serialize' do
    it 'serializes a single resource' do
      result = serializer.serialize(example)
      
      expect(result).to include(id: 1, name: 'Test Example')
    end

    it 'serializes a collection' do
      result = serializer.serialize(collection)
      
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'returns nil for nil resources' do
      result = serializer.serialize(nil)
      
      expect(result).to be_nil
    end
  end
end
