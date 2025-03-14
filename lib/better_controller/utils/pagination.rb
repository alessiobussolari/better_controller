# frozen_string_literal: true

module BetterController
  module Utils
    # Module providing pagination functionality for ActiveRecord collections
    module Pagination
      extend ActiveSupport::Concern

      # Paginate a collection
      # @param collection [ActiveRecord::Relation] The collection to paginate
      # @param page [Integer] The page number
      # @param per_page [Integer] The number of items per page
      # @return [ActiveRecord::Relation] The paginated collection
      def paginate(collection, page: nil, per_page: nil)
        page     = (page || params[:page] || 1).to_i
        per_page = (per_page || params[:per_page] || self.class.pagination_options[:per_page] || 25).to_i

        paginated = collection.page(page).per(per_page)

        # Add pagination metadata
        if respond_to?(:add_meta)
          add_meta(:pagination, pagination_meta(paginated))
        end

        paginated
      end

      # Get pagination metadata
      # @param collection [ActiveRecord::Relation] The paginated collection
      # @return [Hash] The pagination metadata
      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages:  collection.total_pages,
          total_count:  collection.total_count,
          per_page:     collection.limit_value
        }
      end

      # Get pagination links
      # @param collection [ActiveRecord::Relation] The paginated collection
      # @return [Hash] The pagination links
      def pagination_links(collection)
        return {} unless request.present?

        current_page = collection.current_page
        total_pages = collection.total_pages

        links = {
          self: pagination_url(current_page),
          first: pagination_url(1),
          last: pagination_url(total_pages)
        }

        links[:prev] = pagination_url(current_page - 1) if current_page > 1
        links[:next] = pagination_url(current_page + 1) if current_page < total_pages

        links
      end

      private

      # Generate a pagination URL
      # @param page [Integer] The page number
      # @return [String] The pagination URL
      def pagination_url(page)
        uri = URI.parse(request.url)
        params = URI.decode_www_form(uri.query || '').to_h
        params['page'] = page.to_s
        uri.query = URI.encode_www_form(params)
        uri.to_s
      end

      # Module providing class methods for pagination
      module ClassMethods
        # Configure pagination defaults
        # @param options [Hash] Pagination options
        def configure_pagination(options = {})
          class_attribute :pagination_options, default: {
            enabled:  true,
            per_page: 25,
          }.merge(options)
        end
      end
    end
  end
end
