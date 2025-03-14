# frozen_string_literal: true

module BetterController
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
      per_page = (per_page || params[:per_page] || 25).to_i

      paginated = collection.page(page).per(per_page)

      # Add pagination metadata
      if respond_to?(:add_meta)
        add_meta(:pagination, {
                   current_page: paginated.current_page,
                   total_pages:  paginated.total_pages,
                   total_count:  paginated.total_count,
                   per_page:     per_page,
                 })
      end

      paginated
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
