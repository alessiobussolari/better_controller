# frozen_string_literal: true

class ProductsController < ActionController::Base
  include TurboStreamHelper
  include BetterController::Controllers::HtmlController

  # Mock service for testing ActionDsl with all response formats
  # Returns Hash with :success, :collection/:resource, :error keys
  class ProductService
    def self.call(params: {})
      id = params[:id]
      if id
        # Show action - find single product
        if id.to_i.positive?
          product = { id: id.to_i, name: "Product #{id}", price: 29.99 }
          { success: true, resource: product }
        else
          { success: false, error: 'Not found' }
        end
      else
        # Index action - return collection
        products = [
          { id: 1, name: 'Product A', price: 10.99 },
          { id: 2, name: 'Product B', price: 20.50 },
          { id: 3, name: 'Product C', price: 30.00 }
        ]
        { success: true, collection: products }
      end
    end
  end

  action :index do
    service ProductService

    on_success do
      html { render plain: 'HTML Index' }
      json { render json: { data: @result[:collection], meta: { format: 'json' } } }
      turbo_stream { replace :products }
      csv { send_csv @result[:collection], filename: 'products.csv', columns: %i[id name price] }
      xml { render xml: @result[:collection] }
    end
  end

  action :show do
    service ProductService

    on_success do
      html { render plain: "HTML Show: #{@result[:resource][:name]}" }
      json { render json: { data: @result[:resource], meta: { format: 'json' } } }
      csv { send_csv [@result[:resource]], filename: 'product.csv' }
      xml { render xml: @result[:resource] }
    end

    on_error do
      html { render plain: 'Not Found', status: :not_found }
      json { render json: { error: @result[:error] || 'Not found' }, status: :not_found }
      xml { render xml: { error: @result[:error] || 'Not found' }, status: :not_found }
      csv { head :unprocessable_entity }
    end
  end
end
