# frozen_string_literal: true

module BetterController
  module Services
    # Base service class for resource operations
    class Service
      # Get all resources
      # @param ancestry_params [Hash] Ancestry parameters for nested resources
      # @return [ActiveRecord::Relation] Collection of resources
      def all(ancestry_params = {})
        resource_scope(ancestry_params).all
      end

      # Find a specific resource
      # @param ancestry_params [Hash] Ancestry parameters for nested resources
      # @param id [Integer, String] The resource ID
      # @return [Object] The found resource
      def find(ancestry_params = {}, id)
        resource_scope(ancestry_params).find(id)
      end

      # Create a new resource
      # @param ancestry_params [Hash] Ancestry parameters for nested resources
      # @param attributes [Hash] The resource attributes
      # @return [Object] The created resource
      def create(ancestry_params = {}, attributes)
        resource = resource_class.new(prepare_attributes(attributes, ancestry_params))

        resource.save if resource.respond_to?(:save)

        resource
      end

      # Update an existing resource
      # @param ancestry_params [Hash] Ancestry parameters for nested resources
      # @param id [Integer, String] The resource ID
      # @param attributes [Hash] The resource attributes
      # @return [Object] The updated resource
      def update(ancestry_params = {}, id, attributes)
        resource = find(ancestry_params, id)

        resource.update(prepare_attributes(attributes, ancestry_params)) if resource.respond_to?(:update)

        resource
      end

      # Destroy a resource
      # @param ancestry_params [Hash] Ancestry parameters for nested resources
      # @param id [Integer, String] The resource ID
      # @return [Object] The destroyed resource
      def destroy(ancestry_params = {}, id)
        resource = find(ancestry_params, id)

        resource.destroy if resource.respond_to?(:destroy)

        resource
      end

      protected

      # Get the resource class
      # @return [Class] The resource class
      def resource_class
        raise NotImplementedError, "#{self.class.name} must implement #{__method__}"
      end

      # Get the resource scope
      # @param ancestry_params [Hash] Ancestry parameters for nested resources
      # @return [ActiveRecord::Relation] The resource scope
      def resource_scope(ancestry_params = {})
        scope = resource_class

        ancestry_params.each do |key, value|
          key.to_s.sub(/_id$/, '')
          scope = scope.where("#{key}": value) if resource_class.column_names.include?(key.to_s)
        end

        scope
      end

      # Prepare attributes for create/update
      # @param attributes [Hash] The resource attributes
      # @param ancestry_params [Hash] Ancestry parameters for nested resources
      # @return [Hash] The prepared attributes
      def prepare_attributes(attributes, ancestry_params = {})
        prepared = attributes.dup

        ancestry_params.each do |key, value|
          prepared[key] = value if resource_class.column_names.include?(key.to_s)
        end

        prepared
      end
    end
  end
end
