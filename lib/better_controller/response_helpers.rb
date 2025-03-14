# frozen_string_literal: true

module BetterController
  # Module providing helper methods for standardized API responses
  module ResponseHelpers
    extend ActiveSupport::Concern

    # Respond with a success response
    # @param data [Object] The data to include in the response
    # @param status [Symbol, Integer] The HTTP status code
    # @param options [Hash] Additional options for the response
    # @return [Object] The formatted response
    def respond_with_success(data = nil, status: :ok, options: {})
      response = {
        success: true,
        data:    data,
      }.merge(options)

      if defined?(render)
        render json: response, status: status
      else
        response
      end
    end

    # Respond with an error response
    # @param error [Exception, String] The error or error message
    # @param status [Symbol, Integer] The HTTP status code
    # @param options [Hash] Additional options for the response
    # @return [Object] The formatted error response
    def respond_with_error(error = nil, status: :unprocessable_entity, options: {})
      error_message = error.is_a?(Exception) ? error.message : error.to_s
      error_type    = error.is_a?(Exception) ? error.class.name : 'Error'

      response = {
        success: false,
        error:   {
          type:    error_type,
          message: error_message,
        },
      }.merge(options)

      if defined?(render)
        render json: response, status: status
      else
        response
      end
    end

    # Respond with a paginated collection
    # @param collection [Object] The collection to paginate
    # @param options [Hash] Pagination options
    # @return [Object] The paginated response
    def respond_with_pagination(collection, options = {})
      page     = (options[:page] || 1).to_i
      per_page = (options[:per_page] || 25).to_i

      paginated = collection.page(page).per(per_page)

      respond_with_success(
        paginated,
        options: {
          meta: {
            pagination: {
              current_page: paginated.current_page,
              total_pages:  paginated.total_pages,
              total_count:  paginated.total_count,
            },
          },
        }
      )
    end
  end
end
