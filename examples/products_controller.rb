# frozen_string_literal: true

# Example of a controller using BetterController's standard_actions
class ProductsController < ApplicationController
  include BetterController

  # Use the standard_actions helper to generate CRUD actions
  standard_actions Product, paginate: true

  private

  # Strong parameters for Product
  def product_params
    params.require(:product).permit(:name, :description, :price, :category_id)
  end

  # You can still override any of the standard actions if needed
  # For example:
  # def index
  #   execute_action do
  #     products = Product.where(category_id: params[:category_id])
  #     respond_with_pagination(products)
  #   end
  # end
end
