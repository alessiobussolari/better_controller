# frozen_string_literal: true

module BetterController
  module Controllers
    # Module providing standardized RESTful resource controller functionality
    #
    # This module provides CRUD helpers that work with any ActiveRecord model.
    # It does NOT include services or serializers - those are the user's responsibility.
    #
    # @example Basic usage
    #   class UsersController < ApplicationController
    #     include BetterController::Controllers::ResourcesController
    #
    #     private
    #
    #     def resource_class
    #       User
    #     end
    #
    #     def resource_params
    #       params.require(:user).permit(:name, :email)
    #     end
    #   end
    #
    module ResourcesController
      extend ActiveSupport::Concern

      included do
        include BetterController::Controllers::Base
        include BetterController::Controllers::ResponseHelpers
        include BetterController::Utils::ParameterValidation
        include BetterController::Utils::Logging
      end

      # Index action to list all resources
      def index
        execute_action do
          @resources = resource_scope.all
          respond_with_success(serialize_collection(@resources), meta: index_meta)
        end
      end

      # Show action to display a specific resource
      def show
        execute_action do
          @resource = find_resource
          respond_with_success(serialize_resource(@resource), meta: show_meta)
        end
      end

      # Create action to create a new resource
      def create
        execute_action do
          @resource = resource_scope.new(resource_params)

          if @resource.save
            respond_with_success(serialize_resource(@resource), status: :created, meta: create_meta)
          else
            respond_with_error(@resource.errors, status: :unprocessable_entity)
          end
        end
      end

      # Update action to update an existing resource
      def update
        execute_action do
          @resource = find_resource

          if @resource.update(resource_params)
            respond_with_success(serialize_resource(@resource), meta: update_meta)
          else
            respond_with_error(@resource.errors, status: :unprocessable_entity)
          end
        end
      end

      # Destroy action to delete a resource
      def destroy
        execute_action do
          @resource = find_resource

          if @resource.destroy
            respond_with_success(serialize_resource(@resource), meta: destroy_meta)
          else
            respond_with_error(@resource.errors, status: :unprocessable_entity)
          end
        end
      end

      protected

      # Find a resource by id
      # @return [ActiveRecord::Base] The resource
      def find_resource
        resource_scope.find(params[:id])
      end

      # Get the base scope for resources
      # Override this method for nested resources or custom scopes
      # @return [ActiveRecord::Relation] The resource scope
      def resource_scope
        resource_class.all
      end

      # Get the resource class
      # @return [Class] The ActiveRecord model class
      def resource_class
        raise NotImplementedError, "#{self.class.name} must implement #{__method__}"
      end

      # Get the resource parameters
      # @return [ActionController::Parameters] The permitted parameters
      def resource_params
        raise NotImplementedError, "#{self.class.name} must implement #{__method__}"
      end

      # Serialize a single resource
      # Override this method to use your preferred serializer
      # @param resource [ActiveRecord::Base] The resource to serialize
      # @return [Hash] The serialized resource
      def serialize_resource(resource)
        resource.as_json
      end

      # Serialize a collection of resources
      # Override this method to use your preferred serializer
      # @param collection [ActiveRecord::Relation] The collection to serialize
      # @return [Array<Hash>] The serialized collection
      def serialize_collection(collection)
        collection.map { |r| serialize_resource(r) }
      end

      # Get additional metadata for index action
      # @return [Hash] The metadata
      def index_meta
        {}
      end

      # Get additional metadata for show action
      # @return [Hash] The metadata
      def show_meta
        {}
      end

      # Get additional metadata for create action
      # @return [Hash] The metadata
      def create_meta
        {}
      end

      # Get additional metadata for update action
      # @return [Hash] The metadata
      def update_meta
        {}
      end

      # Get additional metadata for destroy action
      # @return [Hash] The metadata
      def destroy_meta
        {}
      end
    end
  end
end
