# frozen_string_literal: true

module BetterController
  module Rendering
    # Concern for rendering ViewComponents
    # Provides helpers for component-based rendering
    module ComponentRenderer
      extend ActiveSupport::Concern

      included do
        helper_method :render_component,
                      :component_tag if respond_to?(:helper_method)
      end

      # Render a ViewComponent
      # @param component_class [Class] Component class
      # @param locals [Hash] Component locals
      # @param options [Hash] Render options
      def render_component(component_class, locals: {}, **options)
        merged_locals = default_component_locals.merge(locals)
        component = component_class.new(**merged_locals)

        if options[:to_string]
          render_to_string(component)
        else
          render component, **options.except(:to_string)
        end
      end

      # Render a component inline (returns string)
      # @param component_class [Class] Component class
      # @param locals [Hash] Component locals
      # @return [String] Rendered content
      def render_component_to_string(component_class, locals: {})
        merged_locals = default_component_locals.merge(locals)
        component = component_class.new(**merged_locals)
        render_to_string(component)
      end

      # Build a component tag (for use in views)
      # @param component_class [Class] Component class
      # @param locals [Hash] Component locals
      # @return [Object] Component instance
      def component_tag(component_class, **locals)
        merged_locals = default_component_locals.merge(locals)
        component_class.new(**merged_locals)
      end

      # Render a collection of components
      # @param collection [Array] Collection of items
      # @param component_class [Class] Component class
      # @param item_key [Symbol] Key to use for each item (default: :item)
      # @param options [Hash] Additional render options
      def render_component_collection(collection, component_class, item_key: :item, **options)
        collection.map do |item|
          locals = options.merge(item_key => item)
          render_component_to_string(component_class, locals: locals)
        end.join.html_safe
      end

      private

      # Get default locals for components
      # @return [Hash] Default locals
      def default_component_locals
        locals = {}

        # Add common context
        locals[:current_user] = current_user if respond_to?(:current_user, true)
        locals[:page_config] = @page_config if @page_config.present?
        locals[:result] = @result if @result.present?

        # Add resource/collection if available
        if @result.is_a?(Hash)
          locals[:resource] = @result[:resource] if @result[:resource].present?
          locals[:collection] = @result[:collection] if @result[:collection].present?
        end

        locals
      end

      # Check if ViewComponent is available
      # @return [Boolean]
      def view_component_available?
        defined?(ViewComponent::Base)
      end
    end
  end
end
