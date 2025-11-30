# frozen_string_literal: true

module BetterController
  module Dsl
    # Builder for response handlers (on_success, on_error blocks)
    # Provides a DSL to define format-specific responses
    class ResponseBuilder
      attr_reader :handlers

      def initialize
        @handlers = {}
      end

      # Define HTML response handler
      # @yield Block to execute for HTML requests
      def html(&block)
        @handlers[:html] = block
      end

      # Define Turbo Stream response handler
      # @yield Block to define turbo streams (evaluated in TurboStreamBuilder context)
      def turbo_stream(&block)
        if block_given?
          builder = TurboStreamBuilder.new
          builder.instance_eval(&block)
          @handlers[:turbo_stream] = builder.build
        end
      end

      # Define JSON response handler
      # @yield Block to execute for JSON requests
      def json(&block)
        @handlers[:json] = block
      end

      # Define CSV response handler
      # @yield Block to execute for CSV requests
      def csv(&block)
        @handlers[:csv] = block
      end

      # Define XML response handler
      # @yield Block to execute for XML requests
      def xml(&block)
        @handlers[:xml] = block
      end

      # Helper: Redirect to a path (for HTML)
      # @param path [String, Symbol] Redirect path or route helper
      # @param options [Hash] Redirect options (notice, alert, etc.)
      def redirect_to(path, **options)
        @handlers[:redirect] = { path: path, options: options }
      end

      # Helper: Render the page (re-render with current page_config)
      # @param status [Symbol] HTTP status code
      def render_page(status: :ok)
        @handlers[:render_page] = { status: status }
      end

      # Helper: Render a specific component
      # @param component_class [Class] ViewComponent class
      # @param locals [Hash] Component locals
      # @param status [Symbol] HTTP status code
      def render_component(component_class, locals: {}, status: :ok)
        @handlers[:render_component] = {
          component: component_class,
          locals: locals,
          status: status
        }
      end

      # Helper: Render a partial
      # @param partial_path [String] Partial path
      # @param locals [Hash] Partial locals
      # @param status [Symbol] HTTP status code
      def render_partial(partial_path, locals: {}, status: :ok)
        @handlers[:render_partial] = {
          partial: partial_path,
          locals: locals,
          status: status
        }
      end

      # Build the handlers configuration
      # @return [Hash] Handlers configuration
      def build
        @handlers
      end
    end
  end
end
