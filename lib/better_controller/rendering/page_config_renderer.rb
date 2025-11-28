# frozen_string_literal: true

module BetterController
  module Rendering
    # Concern for rendering page_config with ViewComponents
    # Provides integration with BetterUI or custom component libraries
    module PageConfigRenderer
      extend ActiveSupport::Concern

      included do
        helper_method :render_page_section,
                      :render_config_component if respond_to?(:helper_method)
      end

      # Render a page with page_config
      # @param config [Hash] Page configuration
      # @param options [Hash] Render options
      def render_with_page_config(config, **options)
        @page_config = config
        component = find_page_component(config)

        if component
          render component.new(config: config), **options
        else
          render **options
        end
      end

      # Render a specific section from page_config
      # @param section_key [Symbol] Section key in page_config
      # @param fallback [Object] Fallback content if section not found
      # @return [String] Rendered content
      def render_page_section(section_key, fallback: nil)
        return fallback unless @page_config&.dig(section_key)

        section_config = @page_config[section_key]
        render_config_component(section_config)
      end

      # Render a component from configuration
      # @param config [Hash] Component configuration
      # @return [String] Rendered content
      def render_config_component(config)
        return '' unless config.is_a?(Hash)

        component_class = resolve_component_class(config)
        return '' unless component_class

        component = component_class.new(**config.except(:component, :type))
        render_to_string(component)
      end

      private

      # Find the page component for a config
      # @param config [Hash] Page configuration
      # @return [Class, nil] Component class
      def find_page_component(config)
        return nil unless config.is_a?(Hash)

        # Try explicit component
        if config[:component]
          return resolve_component_class(config)
        end

        # Try type-based component
        page_type = config[:type]&.to_sym
        return nil unless page_type

        find_type_component(page_type)
      end

      # Find component by page type
      # @param page_type [Symbol] Page type
      # @return [Class, nil] Component class
      def find_type_component(page_type)
        namespace = page_component_namespace
        type_name = page_type.to_s.camelize

        class_names = [
          "#{namespace}::#{type_name}::PageComponent",
          "#{namespace}::#{type_name}Component",
          "#{type_name}::PageComponent",
          "#{type_name}PageComponent"
        ]

        class_names.each do |name|
          begin
            return name.constantize
          rescue NameError
            next
          end
        end

        nil
      end

      # Resolve component class from config
      # @param config [Hash] Configuration with :component key
      # @return [Class, nil] Component class
      def resolve_component_class(config)
        component = config[:component]

        case component
        when Class
          component
        when String, Symbol
          begin
            component.to_s.constantize
          rescue NameError
            nil
          end
        else
          nil
        end
      end

      # Get the page component namespace
      # @return [String] Namespace
      def page_component_namespace
        if BetterController.config.respond_to?(:page_component_namespace)
          BetterController.config.page_component_namespace
        else
          'Templates'
        end
      end
    end
  end
end
