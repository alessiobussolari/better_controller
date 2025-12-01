# frozen_string_literal: true

class PaginatedProductsController < ApplicationController
  include BetterController::Controllers::ResourcesController
  include BetterController::Utils::Pagination

  configure_pagination per_page: 10

  def index
    execute_action do
      products = resource_scope
      products = products.active if params[:active].present?
      products = products.by_category(params[:category]) if params[:category].present?

      paginated = paginate(products)

      respond_with_success(
        serialize_collection(paginated),
        meta: index_meta.merge(pagination: pagination_meta(paginated))
      )
    end
  end

  private

  def resource_class
    Product
  end

  def resource_params
    params.require(:product).permit(:name, :sku, :price, :category, :active, :stock_quantity)
  end

  def serialize_resource(resource)
    resource.as_json(only: %i[id name sku price category active stock_quantity created_at updated_at])
  end
end
