# frozen_string_literal: true

module BetterController
  module Controllers
    module Concerns
      # DSL for registering controller actions with services, pages, and components
      # Provides a declarative way to define controller behavior
      module ActionDsl
        extend ActiveSupport::Concern

        included do
          class_attribute :_registered_actions, default: {}
        end

        class_methods do
          # Register an action with configuration
          # @param name [Symbol] Action name
          # @param options [Hash] Additional options
          # @yield Block evaluated in ActionBuilder context
          #
          # @example Basic action with service
          #   action :index do
          #     service Users::IndexService
          #   end
          #
          # @example Action with page fallback
          #   action :show do
          #     service Users::ShowService
          #     page Users::ShowPage
          #   end
          #
          # @example Action with custom handlers
          #   action :create do
          #     service Users::CreateService
          #     on_success do
          #       html { redirect_to :index }
          #       turbo_stream { prepend :users_list }
          #     end
          #     on_error :validation do
          #       render_page
          #     end
          #   end
          def action(name, **options, &block)
            builder = Dsl::ActionBuilder.new(name, **options)
            builder.instance_eval(&block) if block_given?

            self._registered_actions = _registered_actions.merge(
              name.to_sym => builder.build
            )

            define_action_method(name)
          end

          private

          def define_action_method(name)
            define_method(name) do
              execute_registered_action(name)
            end
          end
        end

        private

        # Execute a registered action
        # @param name [Symbol] Action name
        def execute_registered_action(name)
          config = self.class._registered_actions[name.to_sym]
          raise ActionNotRegisteredError, "Action #{name} not registered" unless config

          # Initialize instance variables
          @result = nil
          @error = nil
          @error_type = nil
          @page_config = nil

          # Execute before callbacks
          execute_callbacks(config[:before_callbacks])

          # Execute service if defined
          if config[:service]
            raw_result = execute_service(config)
            @result = unwrap_result(raw_result)
          end

          # Resolve page_config
          @page_config = resolve_page_config(config, @result)

          # Execute after callbacks
          execute_callbacks(config[:after_callbacks], @result)

          # Determine success/failure and respond
          if action_successful?(@result)
            handle_action_success(config)
          else
            handle_action_error(config)
          end
        end

        # Execute service
        # @param config [Hash] Action configuration
        # @return [Hash, nil] Service result
        def execute_service(config)
          service_class = config[:service]
          service_method = config[:service_method] || :call

          # Build service params
          service_params = build_service_params(config)

          # Instantiate and call service
          service = if service_class.respond_to?(service_method)
                      # Class method style (BetterService pattern)
                      service_class
                    else
                      # Instance method style
                      build_service_instance(service_class, service_params)
                    end

          service.public_send(service_method, **service_params)
        rescue StandardError => e
          @error = e
          @error_type = classify_error(e)
          { success: false, error: e.message, exception: e }
        end

        # Unwrap result if it's a wrapped response (e.g., BetterService::Result)
        # @param result [Object] Raw service result
        # @return [Hash] Normalized hash result
        def unwrap_result(result)
          wrapper_class = BetterController.configuration.wrapped_responses_class

          return result if result.is_a?(Hash)
          return result unless wrapper_class && result.is_a?(wrapper_class)

          # Unwrap BetterService::Result or compatible wrapper
          {
            resource: result.resource,
            collection: result.resource.is_a?(Enumerable) && !result.resource.is_a?(String) ? result.resource : nil,
            success: result.success?,
            errors: result.respond_to?(:validation_errors) ? result.validation_errors : nil,
            error_type: result.meta.is_a?(Hash) ? result.meta[:error_type] : nil,
            message: result.respond_to?(:message) ? result.message : nil
          }.merge(result.meta || {})
        end

        # Build service instance
        # @param service_class [Class] Service class
        # @param params [Hash] Service params
        # @return [Object] Service instance
        def build_service_instance(service_class, params)
          if service_class.instance_method(:initialize).arity.zero?
            service_class.new
          elsif respond_to?(:current_user, true)
            service_class.new(current_user, **params)
          else
            service_class.new(**params)
          end
        end

        # Build service params from request
        # @param config [Hash] Action configuration
        # @return [Hash] Service params
        def build_service_params(config)
          action_prms = action_params(config)
          # Include id in params hash if present, for services that expect it
          if params[:id].present?
            action_prms = action_prms.respond_to?(:merge) ? action_prms.merge(id: params[:id]) : action_prms.to_h.merge(id: params[:id])
          end
          { params: action_prms }
        end

        # Get action params (strong parameters)
        # @param config [Hash] Action configuration
        # @return [ActionController::Parameters, Hash] Permitted params
        def action_params(config)
          return {} unless params.present?

          params_key = config[:params_key] || controller_name.singularize.to_sym
          permitted = config[:permitted_params]

          if permitted.present? && params[params_key].present?
            params.require(params_key).permit(*permitted)
          elsif params[params_key].present?
            params[params_key]
          else
            # Return params without Rails internal keys (controller, action, format, etc.)
            # Keep :id as it's needed by services for show/edit/update/destroy
            filtered_params = params.except(:controller, :action, :format)
            filtered_params.permit! if filtered_params.respond_to?(:permit!)
            filtered_params.to_h.except('controller', 'action', 'format')
          end
        end

        # Resolve page_config from Page class
        # @param config [Hash] Action configuration
        # @param result [Hash, nil] Service result
        # @return [BetterPage::Config, Hash, nil] Page configuration
        def resolve_page_config(config, result)
          return execute_page(config[:page], result) if config[:page]

          nil
        end

        # Execute a Page class to get configuration
        # @param page_class [Class] BetterPage class
        # @param result [Hash, nil] Service result
        # @return [BetterPage::Config, BetterController::Config] Page configuration
        def execute_page(page_class, result)
          normalized = normalize_result(result)

          # Primary data: collection for index, resource for show/edit/etc
          primary_data = normalized[:collection] || normalized[:resource]

          # Instantiate page with BetterPage signature: Page.new(data, user: current_user)
          page = page_class.new(primary_data, user: current_user_if_available)

          # Call the action method (index, show, edit, etc.)
          page_method = action_name.to_sym

          page_result = if page.respond_to?(page_method)
                          page.public_send(page_method)
                        elsif page.respond_to?(:call)
                          page.call
                        else
                          raise ArgumentError, "Page #{page_class} does not respond to #{page_method} or call"
                        end

          # Normalize the page config result
          normalize_page_config(page_result)
        end

        # Normalize page config to ensure compatibility between BetterController::Config and BetterPage::Config
        # @param result [Object] Result from page class
        # @return [BetterController::Config, Object] Normalized page config
        def normalize_page_config(result)
          return result if result.nil?

          config_class = BetterController.configuration.page_config_class

          # If a custom class is configured and result is already of that type, return as-is
          return result if config_class && result.is_a?(config_class)

          # If result is already a BetterController::Config, return as-is
          return result if result.is_a?(BetterController::Config)

          # If result is a Hash, wrap in BetterController::Config
          return BetterController::Config.new(result) if result.is_a?(Hash)

          # Otherwise, return as-is (may be a custom config object)
          result
        end

        # Get current_user if available, nil otherwise
        # @return [Object, nil] Current user or nil
        def current_user_if_available
          respond_to?(:current_user, true) ? current_user : nil
        end

        # Normalize result to hash for consistent access
        # @param result [Hash, Object, nil] Result object or hash
        # @return [Hash] Normalized hash
        def normalize_result(result)
          return {} if result.nil?
          return result if result.is_a?(Hash)
          return result.to_h if result.respond_to?(:to_h)

          {}
        end

        # Deep duplicate a configuration hash
        # @param config [Hash] Configuration to duplicate
        # @return [Hash] Duplicated configuration
        def deep_dup_config(config)
          return config unless config.is_a?(Hash)

          config.deep_dup
        end

        # Determine if the action was successful
        # @param result [Hash, nil] Service result
        # @return [Boolean] Whether the action succeeded
        def action_successful?(result)
          return false if @error.present?

          # Support both Hash with :success key and objects with success? method
          if result.respond_to?(:success?)
            result.success?
          elsif result&.key?(:success)
            result[:success]
          else
            true
          end
        end

        # Classify error type
        # @param error [Exception] The error
        # @return [Symbol] Error type
        def classify_error(error)
          error_class = error.class.name

          # Not Found errors
          if error_class == 'ActiveRecord::RecordNotFound' ||
             error_class == 'BetterService::Errors::Runtime::ResourceNotFoundError' ||
             (defined?(ActiveRecord::RecordNotFound) && error.is_a?(ActiveRecord::RecordNotFound)) ||
             (defined?(BetterService::Errors::Runtime::ResourceNotFoundError) && error.is_a?(BetterService::Errors::Runtime::ResourceNotFoundError))
            :not_found
          # Validation errors
          elsif error_class == 'ActiveRecord::RecordInvalid' ||
                error_class == 'ActiveModel::ValidationError' ||
                error_class == 'BetterService::Errors::Runtime::ValidationError' ||
                (defined?(ActiveRecord::RecordInvalid) && error.is_a?(ActiveRecord::RecordInvalid)) ||
                (defined?(ActiveModel::ValidationError) && error.is_a?(ActiveModel::ValidationError)) ||
                (defined?(BetterService::Errors::Runtime::ValidationError) && error.is_a?(BetterService::Errors::Runtime::ValidationError))
            :validation
          # Authorization errors
          elsif error_class == 'Pundit::NotAuthorizedError' ||
                error_class == 'CanCan::AccessDenied' ||
                error_class == 'BetterService::Errors::Runtime::AuthorizationError' ||
                (defined?(Pundit::NotAuthorizedError) && error.is_a?(Pundit::NotAuthorizedError)) ||
                (defined?(CanCan::AccessDenied) && error.is_a?(CanCan::AccessDenied)) ||
                (defined?(BetterService::Errors::Runtime::AuthorizationError) && error.is_a?(BetterService::Errors::Runtime::AuthorizationError))
            :authorization
          else
            :any
          end
        end

        # Execute callbacks
        # @param callbacks [Array<Proc>, nil] Callbacks to execute
        # @param args [Array] Arguments to pass to callbacks
        def execute_callbacks(callbacks, *args)
          return unless callbacks.present?

          callbacks.each do |callback|
            instance_exec(*args, &callback)
          end
        end

        # Handle successful action
        # @param config [Hash] Action configuration
        def handle_action_success(config)
          handlers = config[:on_success] || {}
          set_success_flash(config)

          respond_to do |format|
            format.html { handle_html_success(config, handlers) }
            format.turbo_stream { handle_turbo_stream_success(config, handlers) }
            format.json { handle_json_success(config, handlers) }
            format.csv { handle_csv_success(config, handlers) }
            format.xml { handle_xml_success(config, handlers) }
          end
        end

        # Handle HTML success response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        def handle_html_success(config, handlers)
          # Check if this is a Turbo Frame request with explicit turbo_frame handler
          if is_turbo_frame_request? && handlers[:turbo_frame].present?
            handle_turbo_frame_response(handlers[:turbo_frame])
          elsif handlers[:redirect]
            redirect_to_path(handlers[:redirect])
          elsif handlers[:html]
            instance_exec(&handlers[:html])
          elsif handlers[:render_page]
            render_page_or_component(config, status: handlers[:render_page][:status])
          elsif handlers[:render_component]
            render_configured_component(handlers[:render_component])
          else
            render_page_or_component(config)
          end
        end

        # Handle Turbo Frame response
        # @param frame_config [Hash] Turbo frame configuration from TurboFrameBuilder
        def handle_turbo_frame_response(frame_config)
          config = frame_config[:config]
          use_layout = frame_config[:layout] # default false

          return render status: :ok, layout: use_layout unless config

          case config[:type]
          when :component
            component = config[:klass].new(**build_component_locals(config[:locals] || {}))
            render component, layout: use_layout
          when :partial
            render partial: config[:path], locals: config[:locals] || {}, layout: use_layout
          when :page
            render_page_config(@page_config, status: config[:status] || :ok, layout: use_layout)
          else
            render status: :ok, layout: use_layout
          end
        end

        # Check if current request is a Turbo Frame request
        # Uses turbo-rails helper if available, otherwise checks Turbo-Frame header
        # @return [Boolean] true if Turbo Frame request
        def is_turbo_frame_request?
          # Check for Turbo-Frame header (standard Turbo behavior)
          request.headers['Turbo-Frame'].present?
        end

        # Handle Turbo Stream success response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        def handle_turbo_stream_success(config, handlers)
          if handlers[:turbo_stream].present?
            render_turbo_streams(handlers[:turbo_stream])
          else
            render_default_turbo_success
          end
        end

        # Handle JSON success response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        def handle_json_success(_config, handlers)
          if handlers[:json]
            instance_exec(&handlers[:json])
          else
            render json: build_json_response(@result)
          end
        end

        # Handle CSV success response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        def handle_csv_success(_config, handlers)
          if handlers[:csv]
            instance_exec(&handlers[:csv])
          else
            # Default: serialize collection as CSV
            collection = @result&.dig(:collection) || [@result&.dig(:resource)].compact
            send_csv(collection) if collection.present?
          end
        end

        # Handle XML success response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        def handle_xml_success(_config, handlers)
          if handlers[:xml]
            instance_exec(&handlers[:xml])
          else
            # Default: serialize as XML
            data = @result&.dig(:collection) || @result&.dig(:resource) || @result
            render xml: data
          end
        end

        # Handle action error
        # @param config [Hash] Action configuration
        def handle_action_error(config)
          error_type = @error_type || determine_error_type(@result)
          handlers = find_error_handlers(config, error_type)

          set_error_flash(error_type, config)

          respond_to do |format|
            format.html { handle_html_error(config, handlers, error_type) }
            format.turbo_stream { handle_turbo_stream_error(config, handlers) }
            format.json { handle_json_error(config, handlers, error_type) }
            format.csv { handle_csv_error(config, handlers, error_type) }
            format.xml { handle_xml_error(config, handlers, error_type) }
          end
        end

        # Determine error type from result
        # @param result [Hash, nil] Service result
        # @return [Symbol] Error type
        def determine_error_type(result)
          return :any unless result.is_a?(Hash)

          # Check for BetterService error codes
          error_code = result[:error_code]
          case error_code
          when :validation_error, :database_error
            return :validation
          when :authorization_error, :unauthorized
            return :authorization
          when :resource_not_found
            return :not_found
          end

          # Check for validation errors (both :errors and :validation_errors keys)
          return :validation if result[:errors].present? || result[:validation_errors].present?

          :any
        end

        # Find error handlers for a specific error type
        # @param config [Hash] Action configuration
        # @param error_type [Symbol] Error type
        # @return [Hash] Error handlers
        def find_error_handlers(config, error_type)
          config[:error_handlers][error_type] ||
            config[:error_handlers][:any] ||
            {}
        end

        # Handle HTML error response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        # @param error_type [Symbol] Error type
        def handle_html_error(config, handlers, error_type)
          status = error_status(error_type)

          # Check if this is a Turbo Frame request with explicit turbo_frame handler
          if is_turbo_frame_request? && handlers[:turbo_frame].present?
            handle_turbo_frame_error_response(handlers[:turbo_frame], status)
          elsif handlers[:redirect]
            redirect_to_path(handlers[:redirect])
          elsif handlers[:html]
            instance_exec(@error, &handlers[:html])
          elsif handlers[:render_page]
            render_page_or_component(config, status: handlers[:render_page][:status] || status)
          else
            render_page_or_component(config, status: status)
          end
        end

        # Handle Turbo Frame error response
        # @param frame_config [Hash] Turbo frame configuration from TurboFrameBuilder
        # @param status [Symbol] HTTP status code
        def handle_turbo_frame_error_response(frame_config, status)
          config = frame_config[:config]
          use_layout = frame_config[:layout] # default false

          return render status: status, layout: use_layout unless config

          case config[:type]
          when :component
            component = config[:klass].new(**build_component_locals(config[:locals] || {}))
            render component, status: status, layout: use_layout
          when :partial
            render partial: config[:path], locals: config[:locals] || {}, status: status, layout: use_layout
          when :page
            render_page_config(@page_config, status: config[:status] || status, layout: use_layout)
          else
            render status: status, layout: use_layout
          end
        end

        # Handle Turbo Stream error response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        def handle_turbo_stream_error(_config, handlers)
          if handlers[:turbo_stream].present?
            render_turbo_streams(handlers[:turbo_stream])
          else
            render_default_turbo_error
          end
        end

        # Handle JSON error response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        # @param error_type [Symbol] Error type
        def handle_json_error(_config, handlers, error_type)
          if handlers[:json]
            instance_exec(@error, &handlers[:json])
          else
            render json: build_json_error_response(@result, @error),
                   status: error_status(error_type)
          end
        end

        # Handle CSV error response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        # @param error_type [Symbol] Error type
        def handle_csv_error(_config, handlers, error_type)
          if handlers[:csv]
            instance_exec(@error, &handlers[:csv])
          else
            # CSV doesn't support structured errors well, return status only
            head error_status(error_type)
          end
        end

        # Handle XML error response
        # @param config [Hash] Action configuration
        # @param handlers [Hash] Response handlers
        # @param error_type [Symbol] Error type
        def handle_xml_error(_config, handlers, error_type)
          if handlers[:xml]
            instance_exec(@error, &handlers[:xml])
          else
            error_response = build_xml_error_response(@result, @error)
            render xml: error_response, status: error_status(error_type)
          end
        end

        # Build XML error response
        # @param result [Hash, nil] Service result
        # @param error [Exception, nil] Exception if any
        # @return [Hash] XML-serializable error response
        def build_xml_error_response(result, error)
          response = { error: {} }
          response[:error][:message] = error&.message || result&.dig(:error) || 'An error occurred'
          response[:error][:errors] = result[:errors] if result&.dig(:errors).present?
          response
        end

        # Redirect to a configured path
        # @param redirect_config [Hash] Redirect configuration
        def redirect_to_path(redirect_config)
          path = redirect_config[:path]
          options = redirect_config[:options] || {}

          resolved_path = path.is_a?(Symbol) ? send(path) : path
          redirect_to resolved_path, **options
        end

        # Render page or component
        # Uses Rails standard render (looks for .html.erb view).
        # For Turbo Frame requests, use the explicit turbo_frame {} DSL handler.
        # @param config [Hash] Action configuration
        # @param status [Symbol] HTTP status
        def render_page_or_component(_config, status: :ok)
          # Rails standard render - looks for action.html.erb
          render status: status
        end

        # Render a configured component
        # @param component_config [Hash] Component configuration
        def render_configured_component(component_config)
          component_class = component_config[:component]
          locals = component_config[:locals] || {}
          status = component_config[:status] || :ok

          # Merge instance variables into locals
          merged_locals = build_component_locals(locals)

          render component_class.new(**merged_locals), status: status
        end

        # Build component locals from instance variables and config
        # @param base_locals [Hash] Base locals from configuration
        # @return [Hash] Merged locals
        def build_component_locals(base_locals)
          locals = base_locals.dup
          locals[:result] = @result if @result.present?
          locals[:resource] = @result[:resource] if @result&.dig(:resource).present?
          locals[:collection] = @result[:collection] if @result&.dig(:collection).present?
          locals
        end

        # Render page_config with appropriate component
        # @param page_config [Hash] Page configuration
        # @param status [Symbol] HTTP status
        # @param layout [Boolean, nil] Layout option (false for Turbo Frame requests)
        def render_page_config(page_config, status: :ok, layout: nil)
          # This method should be overridden by rendering concern
          # Default: assign to instance variable and let Rails render
          @page_config = page_config
          options = { status: status }
          options[:layout] = layout unless layout.nil?
          render(**options)
        end

        # Build JSON response
        # @param result [Hash, nil] Service result
        # @return [Hash] JSON response
        def build_json_response(result)
          return {} unless result

          result.except(:page_config)
        end

        # Build JSON error response
        # @param result [Hash, nil] Service result
        # @param error [Exception, nil] Exception if any
        # @return [Hash] JSON error response
        def build_json_error_response(result, error)
          response = { success: false }
          response[:error] = error&.message || result&.dig(:error) || 'An error occurred'
          response[:errors] = result[:errors] if result&.dig(:errors).present?
          response
        end

        # Get HTTP status for error type
        # @param error_type [Symbol] Error type
        # @return [Symbol] HTTP status
        def error_status(error_type)
          case error_type
          when :not_found then :not_found
          when :authorization then :forbidden
          when :validation then :unprocessable_entity
          else :internal_server_error
          end
        end

        # Set success flash message
        # @param config [Hash] Action configuration
        def set_success_flash(config)
          return unless respond_to?(:flash, true)

          action_name = config[:name]
          message = I18n.t(
            "flash.#{controller_name}.#{action_name}.success",
            default: I18n.t('flash.actions.success', default: nil)
          )
          flash[:notice] = message if message.present?
        end

        # Set error flash message
        # @param error_type [Symbol] Error type
        # @param config [Hash] Action configuration
        def set_error_flash(error_type, config)
          return unless respond_to?(:flash, true)

          action_name = config[:name]
          message = I18n.t(
            "flash.#{controller_name}.#{action_name}.#{error_type}",
            default: I18n.t("flash.errors.#{error_type}", default: nil)
          )
          flash[:alert] = message if message.present?
        end

        # Render Turbo Streams
        # @param streams [Array<Hash>] Stream configurations
        def render_turbo_streams(streams)
          built_streams = build_turbo_streams(streams)

          # If built_streams contains strings (from turbo_stream helper),
          # render them directly with the correct content type
          if built_streams.all? { |s| s.is_a?(String) || s.respond_to?(:to_s) }
            render plain: built_streams.join("\n"), content_type: 'text/vnd.turbo-stream.html'
          else
            # Use Rails' native turbo_stream rendering
            render turbo_stream: built_streams
          end
        end

        # Build Turbo Stream responses
        # @param streams [Array<Hash>] Stream configurations
        # @return [Array] Turbo stream responses
        def build_turbo_streams(streams)
          streams.map { |stream| build_single_turbo_stream(stream) }
        end

        # Build a single Turbo Stream
        # @param stream [Hash] Stream configuration
        # @return [Object] Turbo stream response
        def build_single_turbo_stream(stream)
          target = resolve_turbo_target(stream[:target])
          action = stream[:action]

          case action
          when :remove
            turbo_stream.remove(target)
          when :refresh
            turbo_stream.refresh
          else
            content = resolve_turbo_content(stream)
            turbo_stream.public_send(action, target, content)
          end
        end

        # Resolve Turbo Stream target
        # @param target [Symbol, String, Object] Target specification
        # @return [String] Target ID
        def resolve_turbo_target(target)
          case target
          when Symbol, String
            target.to_s
          else
            # Assume it's a model with dom_id
            helpers.dom_id(target)
          end
        end

        # Resolve Turbo Stream content
        # @param stream [Hash] Stream configuration
        # @return [String, nil] Rendered content
        def resolve_turbo_content(stream)
          if stream[:component]
            render_to_string(stream[:component].new(**build_component_locals(stream[:locals] || {})))
          elsif stream[:partial]
            render_to_string(partial: stream[:partial], locals: stream[:locals] || {})
          end
        end

        # Default Turbo Stream success response
        def render_default_turbo_success
          streams = [turbo_stream.update('flash', partial: 'shared/flash')]
          render turbo_stream: streams
        end

        # Default Turbo Stream error response
        def render_default_turbo_error
          streams = [turbo_stream.update('flash', partial: 'shared/flash')]

          if @result&.dig(:errors).present?
            streams << turbo_stream.update('form_errors',
                                           partial: 'shared/form_errors',
                                           locals: { errors: @result[:errors] })
          end

          render turbo_stream: streams
        end
      end

      # Error raised when action is not registered
      class ActionNotRegisteredError < StandardError; end
    end
  end
end
