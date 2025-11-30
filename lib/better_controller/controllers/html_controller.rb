# frozen_string_literal: true

module BetterController
  module Controllers
    # Main module for HTML controllers with Turbo support
    # Combines ActionDsl, ServiceResponder, and TurboSupport
    #
    # @example Basic usage
    #   class UsersController < ApplicationController
    #     include BetterController::Controllers::HtmlController
    #
    #     action :index do
    #       service Users::IndexService
    #     end
    #
    #     action :show do
    #       service Users::ShowService
    #     end
    #
    #     action :create do
    #       service Users::CreateService
    #
    #       on_success do
    #         html { redirect_to :index }
    #         turbo_stream do
    #           prepend :users_list
    #           flash type: :notice
    #         end
    #       end
    #
    #       on_error :validation do
    #         render_page
    #       end
    #     end
    #   end
    module HtmlController
      extend ActiveSupport::Concern

      # Module containing overrides that need to take precedence
      module Overrides
        # Override render to support Page objects directly
        # @param options [Object] Render options or Page object
        # @param extra_options [Hash] Additional render options
        # @param block [Proc] Optional block
        def render(options = nil, extra_options = {}, &block)
          if page_object?(options)
            render_page_object(options, **extra_options)
          else
            super
          end
        end

        # Render a Page object directly using its ViewComponent
        # Falls back to traditional ERB template if ViewComponent is not available
        # @param page [Object] Page object (responds to view_component_class and build_page)
        # @param status [Symbol] HTTP status code
        # @param options [Hash] Additional render options
        def render_page_object(page, status: :ok, **options)
          @page = page
          @page_config = page.build_page

          # Try to get the ViewComponent class
          begin
            component_class = page.view_component_class
            render component_class.new(config: @page_config), status: status, **options
          rescue NotImplementedError, NameError
            # Fallback: if ViewComponent doesn't exist, use traditional ERB template
            # The template can access @page and @page_config
            super(status: status, **options)
          end
        end

        # Override render_page_config to use BetterUI components if available
        # @param config [Hash] Page configuration
        # @param options [Hash] Render options
        def render_page_config(config, **options)
          @page_config = config
          status = options.delete(:status) || :ok

          # First try to use :klass if present (from Page object)
          component = config[:klass] || resolve_page_component(config)

          if component
            render component.new(config: config), status: status, **options
          else
            # Fallback to default rendering
            render status: status, **options
          end
        end

        private

        # Check if an object is a Page object using duck typing
        # @param obj [Object] Object to check
        # @return [Boolean] True if object is a Page object
        def page_object?(obj)
          obj.respond_to?(:view_component_class) && obj.respond_to?(:build_page)
        end
      end

      included do
        # Include all concerns
        include Concerns::TurboSupport
        include Concerns::ServiceResponder
        include Concerns::CsvSupport
        include Concerns::ActionDsl

        # Include rendering helpers if available
        if defined?(BetterController::Rendering::PageConfigRenderer)
          include BetterController::Rendering::PageConfigRenderer
        end

        if defined?(BetterController::Rendering::ComponentRenderer)
          include BetterController::Rendering::ComponentRenderer
        end

        # Prepend overrides to ensure they take precedence over concern methods
        prepend Overrides

        # Make page_config available to views
        helper_method :page_config if respond_to?(:helper_method)
      end

      # Get the current page_config
      # @return [Hash, nil] The page configuration
      def page_config
        @page_config
      end

      # Get the service result
      # @return [Hash, nil] The service result
      def service_result
        @result || @service_result
      end

      # Get the resource from service result
      # @return [Object, nil] The resource
      def resource
        @resource ||= service_result&.dig(:resource)
      end

      # Get the collection from service result
      # @return [Array, nil] The collection
      def collection
        @collection ||= service_result&.dig(:collection)
      end

      private

      # Resolve the component class for a page config
      # @param config [Hash] Page configuration
      # @return [Class, nil] Component class
      def resolve_page_component(config)
        return nil unless config.is_a?(Hash)

        page_type = config[:type]&.to_sym
        return nil unless page_type

        # Try to find component in configured namespace
        component_class_name = page_component_class_name(page_type)

        begin
          component_class_name.constantize
        rescue NameError
          nil
        end
      end

      # Get the component class name for a page type
      # @param page_type [Symbol] Page type
      # @return [String] Component class name
      def page_component_class_name(page_type)
        namespace = BetterController.config.page_component_namespace
        type_name = page_type.to_s.camelize

        "#{namespace}::#{type_name}::PageComponent"
      end

      # Build locals for component rendering
      # @return [Hash] Component locals
      def component_locals
        {
          page_config: @page_config,
          result: @result,
          resource: resource,
          collection: collection
        }.compact
      end
    end
  end
end
