# frozen_string_literal: true

require 'spec_helper'

# Mock ActiveRecord model for testing
class MockModel
  attr_accessor :id, :name, :email, :errors

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @email = attributes[:email]
    @errors = MockErrors.new
  end

  def as_json(_options = {})
    { id: id, name: name, email: email }
  end

  def save
    if name.nil? || name.empty?
      errors.add(:name, 'is required')
      false
    else
      @id ||= rand(1000)
      true
    end
  end

  def update(attributes)
    if attributes[:name].nil? || attributes[:name].empty?
      errors.add(:name, 'is required')
      false
    else
      attributes.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
      true
    end
  end

  def destroy
    true
  end
end

# Mock errors
class MockErrors
  def initialize
    @errors = {}
  end

  def add(field, message)
    @errors[field] ||= []
    @errors[field] << message
  end

  def any?
    @errors.any?
  end

  def full_messages
    @errors.map { |field, messages| messages.map { |m| "#{field.to_s.capitalize} #{m}" } }.flatten
  end

  def to_hash
    @errors
  end
end

# Mock collection for testing
class MockCollection
  def initialize(items)
    @items = items
  end

  def all
    @items
  end

  def find(id)
    @items.find { |item| item.id == id.to_i } || raise(MockRecordNotFound, "Not found: #{id}")
  end

  def new(attributes = {})
    MockModel.new(attributes)
  end
end

class MockRecordNotFound < StandardError; end

RSpec.describe BetterController::Controllers::ResourcesController do
  let(:test_controller_class) do
    Class.new do
      include BetterController::Controllers::ResourcesController

      attr_accessor :params, :rendered, :action_name

      def initialize
        @params = {}
        @rendered = nil
        @action_name = 'test'
        @performed = false
      end

      def render(options = {})
        @rendered = options
        @performed = true
      end

      def performed?
        @performed
      end

      def resource_class
        @resource_class ||= MockCollection.new([
                                                 MockModel.new(id: 1, name: 'Item 1', email: 'item1@test.com'),
                                                 MockModel.new(id: 2, name: 'Item 2', email: 'item2@test.com')
                                               ])
      end

      def resource_scope
        resource_class
      end

      def resource_params
        params[:resource] || {}
      end

      def log_debug(_message); end

      def log_exception(_exception, _context = {}); end
    end
  end

  let(:controller) { test_controller_class.new }

  before { BetterController.reset_config! }
  after { BetterController.reset_config! }

  describe 'action availability' do
    it { expect(controller).to respond_to(:index) }
    it { expect(controller).to respond_to(:show) }
    it { expect(controller).to respond_to(:create) }
    it { expect(controller).to respond_to(:update) }
    it { expect(controller).to respond_to(:destroy) }
  end

  describe '#index' do
    it 'returns a collection of resources' do
      controller.action_name = 'index'
      controller.index

      expect(controller.rendered[:status]).to eq(:ok)
      expect(controller.rendered[:json][:data]).to be_an(Array)
      expect(controller.rendered[:json][:data].size).to eq(2)
    end

    it 'includes version in meta' do
      controller.index

      expect(controller.rendered[:json][:meta][:version]).to eq('v1')
    end
  end

  describe '#show' do
    it 'returns a single resource' do
      controller.params = { id: 1 }
      controller.action_name = 'show'
      controller.show

      expect(controller.rendered[:status]).to eq(:ok)
      expect(controller.rendered[:json][:data]).to be_a(Hash)
      expect(controller.rendered[:json][:data][:id]).to eq(1)
    end

    it 'includes version in meta' do
      controller.params = { id: 1 }
      controller.show

      expect(controller.rendered[:json][:meta][:version]).to eq('v1')
    end
  end

  describe '#create' do
    context 'with valid params' do
      it 'creates and returns the resource' do
        controller.params = { resource: { name: 'New Item', email: 'new@test.com' } }
        controller.action_name = 'create'
        controller.create

        expect(controller.rendered[:status]).to eq(:created)
        expect(controller.rendered[:json][:data][:name]).to eq('New Item')
      end
    end

    context 'with invalid params' do
      it 'returns error response' do
        controller.params = { resource: { name: '', email: 'new@test.com' } }
        controller.action_name = 'create'
        controller.create

        expect(controller.rendered[:status]).to eq(:unprocessable_entity)
        expect(controller.rendered[:json][:data][:error]).to be_present
      end
    end
  end

  describe '#update' do
    context 'with valid params' do
      it 'updates and returns the resource' do
        controller.params = { id: 1, resource: { name: 'Updated Item' } }
        controller.action_name = 'update'
        controller.update

        expect(controller.rendered[:status]).to eq(:ok)
        expect(controller.rendered[:json][:data][:name]).to eq('Updated Item')
      end
    end

    context 'with invalid params' do
      it 'returns error response' do
        controller.params = { id: 1, resource: { name: '' } }
        controller.action_name = 'update'
        controller.update

        expect(controller.rendered[:status]).to eq(:unprocessable_entity)
      end
    end
  end

  describe '#destroy' do
    it 'destroys the resource and returns success' do
      controller.params = { id: 1 }
      controller.action_name = 'destroy'
      controller.destroy

      expect(controller.rendered[:status]).to eq(:ok)
    end
  end

  describe '#resource_class' do
    it 'raises NotImplementedError when not overridden' do
      base_class = Class.new do
        include BetterController::Controllers::ResourcesController
      end
      base = base_class.new

      expect { base.send(:resource_class) }.to raise_error(NotImplementedError)
    end
  end

  describe '#resource_params' do
    it 'raises NotImplementedError when not overridden' do
      base_class = Class.new do
        include BetterController::Controllers::ResourcesController

        def resource_class
          MockCollection.new([])
        end
      end
      base = base_class.new

      expect { base.send(:resource_params) }.to raise_error(NotImplementedError)
    end
  end

  describe '#serialize_resource' do
    it 'uses as_json by default' do
      model = MockModel.new(id: 1, name: 'Test', email: 'test@test.com')
      result = controller.send(:serialize_resource, model)

      expect(result).to eq({ id: 1, name: 'Test', email: 'test@test.com' })
    end
  end

  describe '#serialize_collection' do
    it 'maps serialize_resource over collection' do
      models = [
        MockModel.new(id: 1, name: 'Test 1', email: 'test1@test.com'),
        MockModel.new(id: 2, name: 'Test 2', email: 'test2@test.com')
      ]
      result = controller.send(:serialize_collection, models)

      expect(result.size).to eq(2)
      expect(result[0][:id]).to eq(1)
      expect(result[1][:id]).to eq(2)
    end
  end

  describe 'meta helpers' do
    it '#index_meta returns empty hash by default' do
      expect(controller.send(:index_meta)).to eq({})
    end

    it '#show_meta returns empty hash by default' do
      expect(controller.send(:show_meta)).to eq({})
    end

    it '#create_meta returns empty hash by default' do
      expect(controller.send(:create_meta)).to eq({})
    end

    it '#update_meta returns empty hash by default' do
      expect(controller.send(:update_meta)).to eq({})
    end

    it '#destroy_meta returns empty hash by default' do
      expect(controller.send(:destroy_meta)).to eq({})
    end
  end

  describe 'custom serialization' do
    let(:custom_serializer_controller_class) do
      Class.new do
        include BetterController::Controllers::ResourcesController

        attr_accessor :params, :rendered, :action_name

        def initialize
          @params = {}
          @rendered = nil
          @action_name = 'test'
          @performed = false
        end

        def render(options = {})
          @rendered = options
          @performed = true
        end

        def performed?
          @performed
        end

        def resource_class
          @resource_class ||= MockCollection.new([
                                                   MockModel.new(id: 1, name: 'Item 1', email: 'item1@test.com')
                                                 ])
        end

        def resource_scope
          resource_class
        end

        def resource_params
          params[:resource] || {}
        end

        # Custom serialization
        def serialize_resource(resource)
          { custom_id: resource.id, custom_name: resource.name.upcase }
        end

        def log_debug(_message); end

        def log_exception(_exception, _context = {}); end
      end
    end

    it 'allows custom serialization via override' do
      ctrl = custom_serializer_controller_class.new
      ctrl.params = { id: 1 }
      ctrl.show

      expect(ctrl.rendered[:json][:data]).to eq({ custom_id: 1, custom_name: 'ITEM 1' })
    end
  end
end
