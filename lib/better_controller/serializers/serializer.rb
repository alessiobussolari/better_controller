# frozen_string_literal: true

module BetterController
  module Serializers
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
      # @return [Hash, Array<Hash>, nil] The serialized resource or collection
      def serialize(resource, options = {})
        return nil if resource.nil?

        # Per le collezioni, utilizziamo serialize_collection
        if resource.respond_to?(:each) && !resource.is_a?(Hash)
          # Per ogni elemento della collezione, creiamo un nuovo serializer
          # e serializziamo l'elemento
          resource.map do |item|
            new_serializer = self.class.new
            new_serializer.object = item if new_serializer.respond_to?(:object=)
            new_serializer.serialize_resource(item, options)
          end
        else
          # Per le risorse singole, utilizziamo l'oggetto corrente o la risorsa passata
          obj = respond_to?(:object) && !object.nil? ? object : resource
          serialize_resource(obj, options)
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
          # Temporaneamente imposta l'oggetto corrente per i metodi del serializer
          old_object = self.object if respond_to?(:object)
          self.object = resource if respond_to?(:object=)
          
          # Chiama il metodo sul serializer
          result[meth] = send(meth) if respond_to?(meth)
          
          # Ripristina l'oggetto precedente
          self.object = old_object if respond_to?(:object=) && defined?(old_object)
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
end
