# frozen_string_literal: true

module BetterController
  module Dsl
    # Builder for Turbo Frame response configuration
    # Provides a DSL to define how to render content for Turbo Frame requests
    #
    # @example Render a component
    #   turbo_frame do
    #     component Users::ListComponent, locals: { title: 'Users' }
    #   end
    #
    # @example Render a partial
    #   turbo_frame do
    #     partial 'users/list', locals: { users: @users }
    #   end
    #
    # @example Render page config
    #   turbo_frame do
    #     render_page status: :ok
    #   end
    #
    # @example With explicit layout control
    #   turbo_frame do
    #     component Users::ListComponent
    #     layout true  # Override default (false)
    #   end
    class TurboFrameBuilder
      def initialize
        @config = nil
        @layout = nil # nil means default (false for turbo_frame)
      end

      # Render a ViewComponent
      # @param klass [Class] ViewComponent class
      # @param locals [Hash] Component locals/attributes
      def component(klass, locals: {})
        @config = { type: :component, klass: klass, locals: locals }
      end

      # Render a partial
      # @param path [String] Partial path
      # @param locals [Hash] Partial locals
      def partial(path, locals: {})
        @config = { type: :partial, path: path, locals: locals }
      end

      # Render using page_config
      # @param status [Symbol] HTTP status code
      def render_page(status: :ok)
        @config = { type: :page, status: status }
      end

      # Control layout rendering
      # @param value [Boolean] Whether to include layout (default: false for Turbo Frame)
      def layout(value)
        @layout = value
      end

      # Build the configuration hash
      # @return [Hash] Configuration for turbo frame rendering
      def build
        {
          config: @config,
          layout: @layout.nil? ? false : @layout
        }
      end
    end
  end
end
