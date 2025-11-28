# frozen_string_literal: true

module BetterController
  module Controllers
    module Concerns
      # Concern for handling service responses
      # Provides a unified way to respond to service results
      # Compatible with BetterService pattern
      module ServiceResponder
        extend ActiveSupport::Concern

        # Respond with a service result
        # Handles success/failure and different response formats
        #
        # @param result [Hash] Service result with :success key
        # @param success_path [String, Symbol, nil] Path to redirect on success
        # @param failure_path [String, Symbol, nil] Path to redirect on failure
        # @yield [format] Optional block for custom format handling
        #
        # @example Basic usage
        #   result = UserService.call(params)
        #   respond_with_service(result, success_path: users_path)
        #
        # @example With custom handling
        #   respond_with_service(result) do |format|
        #     format.html { redirect_to custom_path }
        #   end
        def respond_with_service(result, success_path: nil, failure_path: nil, &block)
          @service_result = result

          if result[:success]
            handle_service_success(result, success_path, &block)
          else
            handle_service_error(result, failure_path, &block)
          end
        end

        # Quick helper for service that returns page_config
        # @param result [Hash] Service result with :page_config
        # @param options [Hash] Render options
        def respond_with_page_config(result, **options)
          @page_config = result[:page_config]
          @service_result = result

          if result[:success]
            render_page_config(@page_config, **options)
          else
            render_page_config(@page_config, status: :unprocessable_entity, **options)
          end
        end

        private

        # Handle successful service response
        # @param result [Hash] Service result
        # @param success_path [String, Symbol, nil] Success redirect path
        def handle_service_success(result, success_path, &block)
          set_service_flash(:notice, result[:message])

          respond_to do |format|
            format.html do
              handle_html_service_success(result, success_path, &block)
            end

            format.turbo_stream do
              handle_turbo_service_success(result, &block)
            end

            format.json do
              handle_json_service_success(result, &block)
            end
          end
        end

        # Handle HTML success response
        # @param result [Hash] Service result
        # @param success_path [String, Symbol, nil] Success redirect path
        def handle_html_service_success(result, success_path)
          if block_given?
            yield
          elsif result[:redirect_to]
            redirect_to result[:redirect_to], notice: result[:message]
          elsif success_path
            redirect_to resolve_path(success_path), notice: result[:message]
          elsif result[:page_config]
            render_page_config(result[:page_config])
          else
            # Default Rails render
            render
          end
        end

        # Handle Turbo Stream success response
        # @param result [Hash] Service result
        def handle_turbo_service_success(result)
          if block_given?
            yield
          elsif result[:turbo_streams]
            render turbo_stream: result[:turbo_streams]
          else
            render_turbo_success(result)
          end
        end

        # Handle JSON success response
        # @param result [Hash] Service result
        def handle_json_service_success(result)
          if block_given?
            yield
          else
            render json: sanitize_json_result(result)
          end
        end

        # Handle service error response
        # @param result [Hash] Service result
        # @param failure_path [String, Symbol, nil] Failure redirect path
        def handle_service_error(result, failure_path, &block)
          set_service_flash(:alert, result[:error])

          respond_to do |format|
            format.html do
              handle_html_service_error(result, failure_path, &block)
            end

            format.turbo_stream do
              handle_turbo_service_error(result, &block)
            end

            format.json do
              handle_json_service_error(result, &block)
            end
          end
        end

        # Handle HTML error response
        # @param result [Hash] Service result
        # @param failure_path [String, Symbol, nil] Failure redirect path
        def handle_html_service_error(result, failure_path)
          if block_given?
            yield
          elsif result[:redirect_to]
            redirect_to result[:redirect_to], alert: result[:error]
          elsif failure_path
            redirect_to resolve_path(failure_path), alert: result[:error]
          elsif result[:page_config]
            render_page_config(result[:page_config], status: :unprocessable_entity)
          else
            render status: :unprocessable_entity
          end
        end

        # Handle Turbo Stream error response
        # @param result [Hash] Service result
        def handle_turbo_service_error(result)
          if block_given?
            yield
          elsif result[:turbo_streams]
            render turbo_stream: result[:turbo_streams]
          else
            render_turbo_error(result)
          end
        end

        # Handle JSON error response
        # @param result [Hash] Service result
        def handle_json_service_error(result)
          if block_given?
            yield
          else
            status = determine_error_status(result)
            render json: sanitize_json_result(result), status: status
          end
        end

        # Render default Turbo Stream success
        # @param result [Hash] Service result
        def render_turbo_success(result)
          streams = []
          streams << turbo_stream.update('flash', partial: 'shared/flash')

          # Add any resource-specific streams
          if result[:resource].present?
            streams.concat(build_resource_streams(result))
          end

          render turbo_stream: streams
        end

        # Render default Turbo Stream error
        # @param result [Hash] Service result
        def render_turbo_error(result)
          streams = []
          streams << turbo_stream.update('flash', partial: 'shared/flash')

          if result[:errors].present?
            streams << turbo_stream.update(
              'form_errors',
              partial: 'shared/form_errors',
              locals: { errors: result[:errors] }
            )
          end

          if result[:resource].present? && result[:resource].respond_to?(:errors)
            streams << turbo_stream.replace(
              helpers.dom_id(result[:resource], :form),
              partial: form_partial_path,
              locals: { resource: result[:resource] }
            )
          end

          render turbo_stream: streams
        end

        # Build resource-specific Turbo Streams
        # @param result [Hash] Service result
        # @return [Array] Turbo stream responses
        def build_resource_streams(result)
          streams = []
          resource = result[:resource]

          case result[:action]
          when :create
            streams << turbo_stream.prepend(
              resource_list_id,
              partial: resource_partial_path,
              locals: { resource: resource }
            )
          when :update
            streams << turbo_stream.replace(
              helpers.dom_id(resource),
              partial: resource_partial_path,
              locals: { resource: resource }
            )
          when :destroy
            streams << turbo_stream.remove(helpers.dom_id(resource))
          end

          streams
        end

        # Get the resource list DOM ID
        # @return [String] List DOM ID
        def resource_list_id
          "#{controller_name}_list"
        end

        # Get the resource partial path
        # @return [String] Partial path
        def resource_partial_path
          "#{controller_name}/#{controller_name.singularize}"
        end

        # Get the form partial path
        # @return [String] Form partial path
        def form_partial_path
          "#{controller_name}/form"
        end

        # Set flash message from service
        # @param type [Symbol] Flash type (:notice, :alert)
        # @param message [String, nil] Flash message
        def set_service_flash(type, message)
          return unless respond_to?(:flash, true)
          return if message.blank?

          flash[type] = message
        end

        # Resolve a path (symbol to actual path)
        # @param path [String, Symbol] Path or route helper name
        # @return [String] Resolved path
        def resolve_path(path)
          path.is_a?(Symbol) ? send(path) : path
        end

        # Sanitize result for JSON response
        # Remove internal keys not meant for API response
        # @param result [Hash] Service result
        # @return [Hash] Sanitized result
        def sanitize_json_result(result)
          result.except(:page_config, :turbo_streams, :redirect_to)
        end

        # Determine HTTP status from result
        # @param result [Hash] Service result
        # @return [Symbol] HTTP status
        def determine_error_status(result)
          return result[:status] if result[:status].present?

          case result[:error_type]
          when :not_found then :not_found
          when :unauthorized then :unauthorized
          when :forbidden then :forbidden
          when :validation then :unprocessable_entity
          else :unprocessable_entity
          end
        end

        # Render page_config with appropriate component
        # This is a hook that can be overridden by rendering concerns
        # @param page_config [Hash] Page configuration
        # @param options [Hash] Render options
        def render_page_config(page_config, **options)
          @page_config = page_config
          status = options.delete(:status) || :ok
          render status: status, **options
        end
      end
    end
  end
end
