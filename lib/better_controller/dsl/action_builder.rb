# frozen_string_literal: true

module BetterController
  module Dsl
    # Builder for action configuration
    # Provides a DSL to define service, page, component, and response handlers
    class ActionBuilder
      attr_reader :name, :config

      # Initialize the builder
      # @param name [Symbol] Action name
      # @param options [Hash] Additional options
      def initialize(name, **options)
        @name = name
        @config = {
          name: name,
          options: options,
          error_handlers: {},
          on_success: nil
        }
      end

      # Define the service class to call
      # @param klass [Class] Service class (should respond to .call or #call)
      # @param method [Symbol] Method to call on the service (default: :call)
      def service(klass, method: :call)
        @config[:service] = klass
        @config[:service_method] = method
      end

      # Define a page class to generate page_config
      # Used as fallback when service doesn't have a viewer
      # @param klass [Class] Page class (should respond to #to_config)
      def page(klass)
        @config[:page] = klass
      end

      # Define a ViewComponent to render directly
      # Used when no page_config is needed
      # @param klass [Class] ViewComponent class
      # @param locals [Hash] Default locals for the component
      def component(klass, locals: {})
        @config[:component] = klass
        @config[:component_locals] = locals
      end

      # Define a block to modify page_config from service
      # @yield [config] Block that receives page_config hash
      def page_config(&block)
        @config[:page_config_modifier] = block
      end

      # Define the Turbo Frame ID for this action
      # @param frame_id [Symbol, String] Frame ID
      def turbo_frame(frame_id)
        @config[:turbo_frame] = frame_id
      end

      # Define params key for strong parameters
      # @param key [Symbol] Params key (e.g., :user, :post)
      def params_key(key)
        @config[:params_key] = key
      end

      # Define permitted params
      # @param attrs [Array<Symbol, Hash>] Permitted attributes
      def permit(*attrs)
        @config[:permitted_params] = attrs
      end

      # Define success handler
      # @yield Block evaluated in ResponseBuilder context
      def on_success(&block)
        builder = ResponseBuilder.new
        builder.instance_eval(&block)
        @config[:on_success] = builder.build
      end

      # Define error handler for specific error type
      # @param type [Symbol] Error type (:validation, :authorization, :not_found, :any)
      # @yield Block evaluated in ResponseBuilder context
      def on_error(type = :any, &block)
        builder = ResponseBuilder.new
        builder.instance_eval(&block)
        @config[:error_handlers][type.to_sym] = builder.build
      end

      # Define before action callback
      # @yield Block to execute before the action
      def before(&block)
        @config[:before_callbacks] ||= []
        @config[:before_callbacks] << block
      end

      # Define after action callback
      # @yield Block to execute after the action (receives result)
      def after(&block)
        @config[:after_callbacks] ||= []
        @config[:after_callbacks] << block
      end

      # Skip authentication for this action
      # @param value [Boolean] Whether to skip authentication
      def skip_authentication(value = true)
        @config[:skip_authentication] = value
      end

      # Skip authorization for this action
      # @param value [Boolean] Whether to skip authorization
      def skip_authorization(value = true)
        @config[:skip_authorization] = value
      end

      # Build the action configuration
      # @return [Hash] Action configuration
      def build
        @config
      end
    end
  end
end
