# frozen_string_literal: true

module BetterController
  # Module providing standardized RESTful resource controller functionality
  module ResourcesController
    extend ActiveSupport::Concern

    included do
      # Include the base BetterController modules
      include BetterController::Base
      include BetterController::ResponseHelpers
      include BetterController::ParameterValidation
      include BetterController::Pagination

      # Configure default pagination
      configure_pagination enabled: true, per_page: 25
    end

    # Index action to list all resources
    def index
      execute_action do
        collection = resource_collection_resolver

        # Apply pagination if enabled
        if self.class.pagination_options[:enabled] && collection.respond_to?(:page)
          @resource_collection = paginate(collection,
                                          page:     params[:page],
                                          per_page: params[:per_page] || self.class.pagination_options[:per_page])
        else
          @resource_collection = collection
        end

        data = serialize_resource(@resource_collection, index_serializer)
        respond_with_success(data, options: { meta: meta })
      end
    end

    # Show action to display a specific resource
    def show
      execute_action do
        @resource = resource_finder

        data = serialize_resource(@resource, show_serializer)
        respond_with_success(data, options: { meta: meta })
      end
    end

    # Create action to create a new resource
    def create
      execute_action do
        @resource = resource_creator

        if @resource.errors.any?
          respond_with_error(@resource.errors, status: :unprocessable_entity)
        else
          data = serialize_resource(@resource, create_serializer)
          respond_with_success(data, status: :created, options: {
                                 message: create_message,
                                 meta:    meta,
                               })
        end
      end
    end

    # Update action to update an existing resource
    def update
      execute_action do
        @resource = resource_updater

        if @resource.errors.any?
          respond_with_error(@resource.errors, status: :unprocessable_entity)
        else
          data = serialize_resource(@resource, update_serializer)
          respond_with_success(data, options: {
                                 message: update_message,
                                 meta:    meta,
                               })
        end
      end
    end

    # Destroy action to delete a resource
    def destroy
      execute_action do
        @resource = resource_destroyer

        if @resource.errors.any?
          respond_with_error(@resource.errors, status: :unprocessable_entity)
        else
          data = serialize_resource(@resource, destroy_serializer)
          respond_with_success(data, options: {
                                 message: destroy_message,
                                 meta:    meta,
                               })
        end
      end
    end

    protected

    # Serialize a resource using the specified serializer
    # @param resource [Object] The resource to serialize
    # @param serializer_class [Class] The serializer class
    # @return [Hash, Array<Hash>] The serialized resource
    def serialize_resource(resource, serializer_class)
      return resource unless serializer_class && defined?(serializer_class)

      serializer = serializer_class.new
      serializer.serialize(resource, serialization_options)
    end

    # Get serialization options
    # @return [Hash] The serialization options
    def serialization_options
      {}
    end

    # Get the serializer for index action
    # @return [Class] The serializer class
    def index_serializer
      resource_serializer
    end

    # Get the serializer for show action
    # @return [Class] The serializer class
    def show_serializer
      resource_serializer
    end

    # Get the serializer for create action
    # @return [Class] The serializer class
    def create_serializer
      resource_serializer
    end

    # Get the serializer for update action
    # @return [Class] The serializer class
    def update_serializer
      resource_serializer
    end

    # Get the serializer for destroy action
    # @return [Class] The serializer class
    def destroy_serializer
      resource_serializer
    end

    # Get the resource serializer class
    # @return [Class] The serializer class
    def resource_serializer
      nil
    end

    # Add metadata to the response
    # @param key [Symbol] The metadata key
    # @param value [Object] The metadata value
    def add_meta(key, value)
      meta[key] = value
    end

    # Get the metadata hash
    # @return [Hash] The metadata
    def meta
      @meta ||= {}
    end

    # Get the resource service
    # @return [Object] The resource service
    def resource_service
      resource_service_class.new
    end

    # Get the resource service class
    # @return [Class] The resource service class
    def resource_service_class
      raise NotImplementedError, "#{self.class.name} must implement #{__method__}"
    end

    # Get the root key for resource parameters
    # @return [Symbol] The root key
    def resource_params_root_key
      raise NotImplementedError, "#{self.class.name} must implement #{__method__}"
    end

    # Get the message for create action
    # @return [String, nil] The message
    def create_message
      nil
    end

    # Get the message for update action
    # @return [String, nil] The message
    def update_message
      nil
    end

    # Get the message for destroy action
    # @return [String, nil] The message
    def destroy_message
      nil
    end

    # Get the resource parameters
    # @return [Hash] The resource parameters
    def resource_params
      @resource_params ||= params.require(resource_params_root_key).permit!
    end

    # Resolve the resource collection
    # @return [Object] The resource collection
    def resource_collection_resolver
      resource_service.all(ancestry_key_params)
    end

    # Find a specific resource
    # @return [Object] The resource
    def resource_finder
      resource_service.find(ancestry_key_params, resource_key_param)
    end

    # Create a new resource
    # @return [Object] The created resource
    def resource_creator
      resource_service.create(ancestry_key_params, resource_create_params)
    end

    # Update an existing resource
    # @return [Object] The updated resource
    def resource_updater
      resource_service.update(ancestry_key_params, resource_key_param, resource_update_params)
    end

    # Destroy a resource
    # @return [Object] The destroyed resource
    def resource_destroyer
      resource_service.destroy(ancestry_key_params, resource_key_param)
    end

    # Get the resource key parameter
    # @return [String, Integer] The resource key
    def resource_key_param
      params[:id]
    end

    # Get the ancestry key parameters
    # @return [Hash] The ancestry key parameters
    def ancestry_key_params
      {}
    end

    # Get the parameters for creating a resource
    # @return [Hash] The create parameters
    def resource_create_params
      resource_params
    end

    # Get the parameters for updating a resource
    # @return [Hash] The update parameters
    def resource_update_params
      resource_params
    end
  end
end
