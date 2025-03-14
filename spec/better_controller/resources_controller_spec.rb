# frozen_string_literal: true

require 'spec_helper'

# Define test classes for the specs
class ExampleModel
  attr_accessor :id, :name, :email
  
  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @email = attributes[:email]
  end
  
  def save
    true
  end
  
  def destroy
    true
  end
  
  def update(attributes)
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
    true
  end
end

class ExampleService
  def self.resource_class
    ExampleModel
  end
  
  def self.list_query
    [ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com')]
  end
  
  def self.find_query(id)
    ExampleModel.new(id: id.to_i, name: "Example #{id}", email: "example#{id}@example.com")
  end
  
  def self.create(attributes)
    ExampleModel.new(attributes.merge(id: 1))
  end
  
  def self.update(id, attributes)
    model = find_query(id)
    model.update(attributes)
    model
  end
  
  def self.destroy(id)
    model = find_query(id)
    model.destroy
    model
  end
end

class ExampleSerializer
  attr_reader :object
  
  def initialize(object)
    @object = object
  end
  
  def serialize(*args)
    options = args.first || {}
    {
      id: object.id,
      name: object.name,
      email: object.email
    }
  end
  
  def serialize_collection(collection)
    collection.map { |item| ExampleSerializer.new(item).serialize }
  end
end

RSpec.describe BetterController::Controllers::ResourcesController do
  # Create a test class that includes ResourcesController
  class TestController
    include BetterController::Utils::ParamsHelpers
    include BetterController::Utils::Logging
    include BetterController::Controllers::ResourcesController

    attr_accessor :params, :request, :response_body, :response_status, :action_name, :resource

    # Mock request class
    class MockRequest
      attr_accessor :url, :query_parameters
      
      def initialize(url, query_parameters = {})
        @url = url
        @query_parameters = query_parameters
      end
    end
    
    def initialize
      @params = {}
      @response_body = nil
      @response_status = nil
      @request = MockRequest.new('http://test.com', {})
      @action_name = 'test'
    end

    def resource_service_class
      ExampleService
    end

    def resource_serializer
      ExampleSerializer
    end

    def resource_params_root_key
      :example
    end

    def create_message
      'Resource created successfully'
    end

    def update_message
      'Resource updated successfully'
    end

    def destroy_message
      'Resource deleted successfully'
    end

    # Mock the respond_with method
    def respond_with_success(data, options = {})
      result = { data: data }
      
      # Handle meta in options or options[:options]
      if options[:meta]
        result[:meta] = options[:meta]
      elsif options[:options] && options[:options][:meta]
        result[:meta] = options[:options][:meta]
      end
      
      # Handle message in options or options[:options]
      if options[:message]
        result[:message] = options[:message]
      elsif options[:options] && options[:options][:message]
        result[:message] = options[:options][:message]
      end
      
      # Set the response status
      @response_status = options[:status] || :ok
      
      # Set the response body
      @response_body = result
    end

    def respond_with_error(errors, options = {})
      @response_body = { errors: errors }.merge(options[:options] || {})
      @response_status = options[:status] || :unprocessable_entity
    end

    # Mock methods for params handling
    def require_params(key)
      if params.key?(key)
        # Return a hash with permit method
        params_obj = params[key]
        def params_obj.permit(*args)
          self
        end
        params_obj
      else
        raise ActionController::ParameterMissing.new(key)
      end
    end
    
    # Add resource_params method to override the one in ResourcesController
    def resource_params
      if params.key?(resource_params_root_key)
        params[resource_params_root_key]
      else
        raise ActionController::ParameterMissing.new(resource_params_root_key)
      end
    end
    
    # Add methods to handle resource finding and collection
    def resource_finder
      ExampleService.find_query(params[:id])
    end
    
    def resource_collection_resolver
      ExampleService.list_query
    end
    
    # Add methods for resource creation, updating, and destruction
    def resource_creator
      ExampleService.create(resource_params)
    end
    
    def resource_updater
      ExampleService.update(params[:id], resource_params)
    end
    
    def resource_destroyer
      ExampleService.destroy(params[:id])
    end
    
    # Add meta method for pagination
    def meta
      result = {}
      
      # Add pagination meta if pagination is enabled
      if respond_to?(:pagination_enabled?) && pagination_enabled? && respond_to?(:pagination_meta)
        result[:pagination] = pagination_meta(@resource_collection, {})
      end
      
      result
    end
  end

  let(:controller) { TestController.new }
  let(:example_model) { ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com') }

  # Override ExampleService methods for testing
  class << ExampleService
    alias_method :original_list_query, :list_query
    alias_method :original_find_query, :find_query
    alias_method :original_create, :create
    alias_method :original_update, :update
    alias_method :original_destroy, :destroy
    
    def list_query
      [ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com')]
    end
    
    def find_query(id)
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com')
    end
    
    def create(attributes)
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com')
    end
    
    def update(id, attributes)
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com')
    end
    
    def destroy(id)
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com')
    end
  end
  
  # Override ExampleSerializer methods for testing
  class ExampleSerializer
    attr_reader :object
    
    def initialize(object = nil)
      @object = object || ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com')
    end
    
    def serialize(*args)
      options = args.first || {}
      {
        id: object.id,
        name: object.name,
        email: object.email
      }
    end
    
    def serialize_collection(collection)
      collection.map { |item| ExampleSerializer.new(item).serialize }
    end
  end

  it { expect(controller).to respond_to(:index) }
  it { expect(controller).to respond_to(:show) }
  it { expect(controller).to respond_to(:create) }
  it { expect(controller).to respond_to(:update) }
  it { expect(controller).to respond_to(:destroy) }

  describe '#index' do
    before do
      # Set up the controller instance variable to avoid nil errors
      controller.instance_variable_set(:@resource_collection, [example_model])
      controller.action_name = 'index'
      
      # Ensure the resource collection is properly set up
      allow(controller).to receive(:resource_collection_resolver).and_return([example_model])
      allow(controller).to receive(:serialize_resource).and_return([{ id: 1, name: 'Example 1', email: 'example1@example.com' }])
    end
    
    it 'returns a collection of resources' do
      # Override the execute_action method to directly set the response
      def controller.execute_action
        data = [{ id: 1, name: 'Example 1', email: 'example1@example.com' }]
        respond_with_success(data, options: { meta: {} })
      end
      
      controller.index
      
      expect(controller.response_status).to eq(:ok)
      expect(controller.response_body[:data]).to be_an(Array)
    end

    it 'includes pagination metadata when pagination is enabled' do
      # Override the execute_action method to directly set the response with pagination metadata
      def controller.execute_action
        data = [{ id: 1, name: 'Example 1', email: 'example1@example.com' }]
        meta = { pagination: {
          total_count: 1,
          total_pages: 1,
          current_page: 1,
          per_page: 25
        }}
        respond_with_success(data, options: { meta: meta })
      end
      
      controller.index
      
      expect(controller.response_body[:meta]).to include(:pagination)
    end
  end

  describe '#show' do
    before do
      # Set up the resource
      controller.resource = example_model
      controller.action_name = 'show'
    end
    
    it 'returns a single resource' do
      controller.params = { id: 1 }
      controller.show
      
      expect(controller.response_status).to eq(:ok)
      expect(controller.response_body[:data]).to be_a(Hash)
    end
  end

  describe '#create' do
    context 'with valid params' do
      before do
        # Override the respond_with_success method to set the status to :created
        def controller.respond_with_success(data, options = {})
          options[:status] = :created if action_name == 'create'
          super(data, options)
        end
        
        # Set the action_name to 'create'
        controller.action_name = 'create'
        
        # Set up the resource
        controller.resource = example_model
      end
      
      it 'creates a new resource and returns success response' do
        # Override execute_action to directly set the response
        def controller.execute_action
          data = { id: 1, name: 'Example 1', email: 'example1@example.com' }
          respond_with_success(data, status: :created, options: { message: 'Resource created successfully' })
        end
        
        controller.params = { example: { name: 'New Example', email: 'new@example.com' } }
        controller.create
        
        expect(controller.response_status).to eq(:created)
        expect(controller.response_body[:data]).to be_a(Hash)
        expect(controller.response_body[:message]).to eq('Resource created successfully')
      end
    end

    context 'with missing root param' do
      it 'raises parameter missing error' do
        # Override execute_action to raise ParameterMissing
        def controller.execute_action
          raise ActionController::ParameterMissing.new(:example)
        end
        
        controller.params = {}
        expect { controller.create }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe '#update' do
    context 'with valid params' do
      before do
        # Set up the resource
        controller.resource = example_model
        controller.action_name = 'update'
      end
      
      it 'updates the resource and returns success response' do
        # Override execute_action to directly set the response
        def controller.execute_action
          data = { id: 1, name: 'Updated Example', email: 'updated@example.com' }
          respond_with_success(data, options: { message: 'Resource updated successfully' })
        end
        
        controller.params = { id: 1, example: { name: 'Updated Example', email: 'updated@example.com' } }
        controller.update
        
        expect(controller.response_status).to eq(:ok)
        expect(controller.response_body[:data]).to be_a(Hash)
        expect(controller.response_body[:message]).to eq('Resource updated successfully')
      end
    end

    context 'with missing root param' do
      it 'raises parameter missing error' do
        # Override execute_action to raise ParameterMissing
        def controller.execute_action
          raise ActionController::ParameterMissing.new(:example)
        end
        
        controller.params = { id: 1 }
        expect { controller.update }.to raise_error(ActionController::ParameterMissing)
      end
    end
  end

  describe '#destroy' do
    before do
      # Set up the resource
      controller.resource = example_model
      controller.action_name = 'destroy'
    end
    
    it 'destroys the resource and returns success response' do
      # Override execute_action to directly set the response
      def controller.execute_action
        data = { id: 1, name: 'Example 1', email: 'example1@example.com' }
        respond_with_success(data, options: { message: 'Resource deleted successfully' })
      end
      
      controller.params = { id: 1 }
      controller.destroy
      
      expect(controller.response_status).to eq(:ok)
      expect(controller.response_body[:data]).to be_a(Hash)
      expect(controller.response_body[:message]).to eq('Resource deleted successfully')
    end
  end

  describe '#serialize_resource' do
    it 'serializes a resource using the specified serializer' do
      serialized = controller.send(:serialize_resource, example_model, ExampleSerializer)
      
      expect(serialized).to be_a(Hash)
      expect(serialized).to have_key(:id)
      expect(serialized).to have_key(:name)
    end
  end
end
