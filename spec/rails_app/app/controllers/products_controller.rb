# frozen_string_literal: true

class ProductsController < ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Product
  end

  def resource_params
    params.require(:product).permit(:name, :sku, :price, :category, :active, :stock_quantity)
  end

  def serialize_resource(resource)
    resource.as_json(only: %i[id name sku price category active stock_quantity created_at])
  end
end
