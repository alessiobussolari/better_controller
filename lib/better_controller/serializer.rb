# frozen_string_literal: true

module BetterController
  # Base module for serializing resources
  module Serializer
    extend ActiveSupport::Concern

    class_methods do
      # Define attributes to be included in the serialized output
      # @param attrs [Array<Symbol>] The attributes to include
      def attributes(*attrs)
        @attributes ||= []
        @attributes.concat(attrs) if attrs.any?
        @attributes
      end

      # Define associations to be included in the serialized output
      # @param assocs [Hash] The associations to include
      def associations(assocs = {})
        @associations ||= {}
        @associations.merge!(assocs) if assocs.any?
        @associations
      end

      # Define methods to be included in the serialized output
      # @param meths [Array<Symbol>] The methods to include
      def methods(*meths)
        @methods ||= []
        @methods.concat(meths) if meths.any?
        @methods
      end
    end

    # Serialize a resource
    # @param resource [Object] The resource to serialize
    # @param options [Hash] Serialization options
    # @return [Hash] The serialized resource
    def serialize(resource, options = {})
      return nil if resource.nil?

      if resource.respond_to?(:each) && !resource.is_a?(Hash)
        serialize_collection(resource, options)
      else
        serialize_resource(resource, options)
      end
    end

    # Serialize a collection of resources
    # @param collection [Array, ActiveRecord::Relation] The collection to serialize
    # @param options [Hash] Serialization options
    # @return [Array<Hash>] The serialized collection
    def serialize_collection(collection, options = {})
      collection.map { |resource| serialize_resource(resource, options) }
    end

    # Serialize a single resource
    # @param resource [Object] The resource to serialize
    # @param options [Hash] Serialization options
    # @return [Hash] The serialized resource
    def serialize_resource(resource, options = {})
      result = {}

      # Add attributes
      self.class.attributes.each do |attr|
        result[attr] = resource.send(attr) if resource.respond_to?(attr)
      end

      # Add methods
      self.class.methods.each do |meth|
        result[meth] = resource.send(meth) if resource.respond_to?(meth)
      end

      # Add associations
      self.class.associations.each do |name, serializer_class|
        next unless resource.respond_to?(name)

        association  = resource.send(name)
        serializer   = serializer_class.new
        result[name] = serializer.serialize(association, options)
      end

      result
    end
  end
end
