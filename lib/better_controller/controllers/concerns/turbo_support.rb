# frozen_string_literal: true

module BetterController
  module Controllers
    module Concerns
      # Concern for Turbo Frames and Turbo Streams support
      # Provides helpers for working with Hotwire/Turbo
      module TurboSupport
        extend ActiveSupport::Concern

        included do
          # Helper methods available in views
          helper_method :turbo_frame_request?,
                        :turbo_stream_request?,
                        :current_turbo_frame,
                        :turbo_native_app? if respond_to?(:helper_method)
        end

        # Check if this is a Turbo Frame request
        # @return [Boolean]
        def turbo_frame_request?
          request.headers['Turbo-Frame'].present?
        end

        # Check if this is a Turbo Stream request
        # @return [Boolean]
        def turbo_stream_request?
          request.format.turbo_stream? ||
            request.headers['Accept']&.include?('text/vnd.turbo-stream.html')
        end

        # Get the current Turbo Frame ID
        # @return [String, nil]
        def current_turbo_frame
          request.headers['Turbo-Frame']
        end

        # Check if request is from a Turbo Native app
        # @return [Boolean]
        def turbo_native_app?
          request.user_agent&.include?('Turbo Native')
        end

        # Render multiple Turbo Streams
        # @param streams [Array<Hash>] Stream configurations
        # @yield Optional block for additional streams
        #
        # @example
        #   render_streams([
        #     { action: :replace, target: :user_1, partial: 'users/user' },
        #     { action: :remove, target: :notification }
        #   ])
        def render_streams(streams, &block)
          built_streams = streams.map { |s| build_stream(s) }

          if block_given?
            additional = []
            yield(additional)
            built_streams.concat(additional)
          end

          render turbo_stream: built_streams
        end

        # Build a single Turbo Stream response
        # @param config [Hash] Stream configuration
        # @return [Object] Turbo stream response
        def build_stream(config)
          action = config[:action]

          case action
          when :refresh
            turbo_stream.refresh
          when :remove
            target = resolve_target(config[:target])
            turbo_stream.remove(target)
          else
            target = resolve_target(config[:target])
            content = resolve_stream_content(config)
            turbo_stream.public_send(action, target, content)
          end
        end

        # Resolve target to DOM ID
        # @param target [Symbol, String, Object] Target
        # @return [String] DOM ID
        def resolve_target(target)
          case target
          when Symbol, String
            target.to_s
          else
            helpers.dom_id(target)
          end
        end

        # Resolve stream content
        # @param config [Hash] Stream configuration
        # @return [String, nil] Rendered content
        def resolve_stream_content(config)
          if config[:component]
            locals = build_stream_locals(config[:locals])
            render_to_string(config[:component].new(**locals))
          elsif config[:partial]
            render_to_string(partial: config[:partial], locals: config[:locals] || {})
          elsif config[:html]
            config[:html]
          end
        end

        # Build locals for stream rendering
        # @param base_locals [Hash] Base locals
        # @return [Hash] Merged locals
        def build_stream_locals(base_locals)
          locals = (base_locals || {}).dup

          # Add common instance variables
          locals[:result] = @result if instance_variable_defined?(:@result) && @result.present?
          locals[:resource] = @resource if instance_variable_defined?(:@resource) && @resource.present?

          locals
        end

        # Stream: Append to a target
        # @param target [Symbol, String, Object] Target
        # @param options [Hash] Render options
        # @return [Object] Turbo stream
        def stream_append(target, **options)
          build_stream({ action: :append, target: target }.merge(options))
        end

        # Stream: Prepend to a target
        # @param target [Symbol, String, Object] Target
        # @param options [Hash] Render options
        # @return [Object] Turbo stream
        def stream_prepend(target, **options)
          build_stream({ action: :prepend, target: target }.merge(options))
        end

        # Stream: Replace a target
        # @param target [Symbol, String, Object] Target
        # @param options [Hash] Render options
        # @return [Object] Turbo stream
        def stream_replace(target, **options)
          build_stream({ action: :replace, target: target }.merge(options))
        end

        # Stream: Update a target's content
        # @param target [Symbol, String, Object] Target
        # @param options [Hash] Render options
        # @return [Object] Turbo stream
        def stream_update(target, **options)
          build_stream({ action: :update, target: target }.merge(options))
        end

        # Stream: Remove a target
        # @param target [Symbol, String, Object] Target
        # @return [Object] Turbo stream
        def stream_remove(target)
          build_stream({ action: :remove, target: target })
        end

        # Stream: Add content before a target
        # @param target [Symbol, String, Object] Target
        # @param options [Hash] Render options
        # @return [Object] Turbo stream
        def stream_before(target, **options)
          build_stream({ action: :before, target: target }.merge(options))
        end

        # Stream: Add content after a target
        # @param target [Symbol, String, Object] Target
        # @param options [Hash] Render options
        # @return [Object] Turbo stream
        def stream_after(target, **options)
          build_stream({ action: :after, target: target }.merge(options))
        end

        # Stream: Update flash message
        # @param type [Symbol] Flash type
        # @param message [String, nil] Optional message
        # @return [Object] Turbo stream
        def stream_flash(type: :notice, message: nil)
          locals = { type: type }
          locals[:message] = message if message.present?

          stream_update(:flash, partial: 'shared/flash', locals: locals)
        end

        # Stream: Update form errors
        # @param errors [Object] Errors (ActiveModel::Errors or Hash)
        # @param target [Symbol, String] Target ID
        # @return [Object] Turbo stream
        def stream_form_errors(errors, target: :form_errors)
          stream_update(target, partial: 'shared/form_errors', locals: { errors: errors })
        end

        # Respond with Turbo Streams only if it's a Turbo Stream request
        # Falls back to regular rendering otherwise
        # @yield Block that provides turbo streams array
        def respond_with_turbo_stream
          if turbo_stream_request?
            streams = []
            yield(streams) if block_given?
            render turbo_stream: streams
          else
            yield if block_given?
          end
        end

        # Redirect with Turbo-compatible behavior
        # Uses Turbo redirect status codes
        # @param path [String] Redirect path
        # @param options [Hash] Redirect options
        def turbo_redirect_to(path, **options)
          # Turbo requires 303 for redirects after form submissions
          status = options.delete(:status) || :see_other
          redirect_to path, status: status, **options
        end

        # Render with Turbo Frame support
        # Automatically targets the frame if present
        # @param options [Hash] Render options
        def render_in_frame(**options)
          if turbo_frame_request?
            options[:layout] = false unless options.key?(:layout)
          end

          render(**options)
        end
      end
    end
  end
end
