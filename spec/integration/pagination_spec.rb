# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaginatedProductsController, type: :controller do
  describe 'Pagination Integration' do
    before do
      50.times do |i|
        Product.create!(
          name: "Product #{i + 1}",
          sku: "SKU-#{format('%03d', i + 1)}",
          price: (10.0 + i).round(2),
          category: %w[electronics clothing food][i % 3],
          active: i.even?,
          stock_quantity: i * 10
        )
      end
    end

    describe 'GET #index with pagination' do
      it 'returns paginated results with default per_page' do
        get :index, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data'].length).to eq(10)
      end

      it 'includes pagination metadata' do
        get :index, format: :json
        json = JSON.parse(response.body)
        pagination = json['meta']['pagination']

        expect(pagination).to be_present
        expect(pagination['current_page']).to eq(1)
        expect(pagination['total_pages']).to eq(5)
        expect(pagination['total_count']).to eq(50)
        expect(pagination['per_page']).to eq(10)
      end

      it 'respects page parameter' do
        get :index, params: { page: 2 }, format: :json
        json = JSON.parse(response.body)

        expect(json['meta']['pagination']['current_page']).to eq(2)
        first_product = json['data'].first
        expect(first_product['name']).to eq('Product 11')
      end

      it 'respects per_page parameter' do
        get :index, params: { per_page: 5 }, format: :json
        json = JSON.parse(response.body)

        expect(json['data'].length).to eq(5)
        expect(json['meta']['pagination']['total_pages']).to eq(10)
        expect(json['meta']['pagination']['per_page']).to eq(5)
      end

      it 'handles last page correctly' do
        get :index, params: { page: 5 }, format: :json
        json = JSON.parse(response.body)

        expect(json['data'].length).to eq(10)
        expect(json['meta']['pagination']['current_page']).to eq(5)
      end

      it 'handles page beyond total pages gracefully' do
        get :index, params: { page: 100 }, format: :json
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(json['data']).to be_empty
      end

      it 'handles page 0 as page 1' do
        get :index, params: { page: 0 }, format: :json
        json = JSON.parse(response.body)

        expect(json['meta']['pagination']['current_page']).to eq(1)
      end

      it 'returns products in correct order' do
        get :index, format: :json
        json = JSON.parse(response.body)
        names = json['data'].map { |p| p['name'] }

        expect(names.first).to eq('Product 1')
        expect(names.last).to eq('Product 10')
      end
    end

    describe 'Pagination with filters' do
      it 'paginates active products only' do
        get :index, params: { active: true }, format: :json
        json = JSON.parse(response.body)

        expect(json['meta']['pagination']['total_count']).to eq(25)
        json['data'].each do |product|
          expect(product['active']).to be true
        end
      end

      it 'paginates by category' do
        get :index, params: { category: 'electronics' }, format: :json
        json = JSON.parse(response.body)

        # 50 products, 3 categories, ~17 electronics
        expect(json['meta']['pagination']['total_count']).to eq(17)
        json['data'].each do |product|
          expect(product['category']).to eq('electronics')
        end
      end

      it 'combines filters with pagination' do
        get :index, params: { category: 'electronics', page: 2, per_page: 5 }, format: :json
        json = JSON.parse(response.body)

        expect(json['data'].length).to eq(5)
        expect(json['meta']['pagination']['current_page']).to eq(2)
      end
    end

    describe 'Pagination with empty collection' do
      before { Product.destroy_all }

      it 'returns empty data with pagination metadata' do
        get :index, format: :json
        json = JSON.parse(response.body)

        expect(json['data']).to be_empty
        expect(json['meta']['pagination']['total_count']).to eq(0)
        expect(json['meta']['pagination']['total_pages']).to eq(0)
        expect(json['meta']['pagination']['current_page']).to eq(1)
      end
    end

    describe 'Pagination metadata structure' do
      it 'includes all required pagination fields' do
        get :index, format: :json
        json = JSON.parse(response.body)
        pagination = json['meta']['pagination']

        expect(pagination).to have_key('current_page')
        expect(pagination).to have_key('total_pages')
        expect(pagination).to have_key('total_count')
        expect(pagination).to have_key('per_page')
      end

      it 'includes API version in meta' do
        get :index, format: :json
        json = JSON.parse(response.body)

        expect(json['meta']['version']).to eq('v1')
      end
    end
  end

  describe 'CRUD operations with pagination controller' do
    let!(:product) do
      Product.create!(
        name: 'Test Product',
        sku: 'TEST-001',
        price: 99.99,
        category: 'electronics',
        active: true,
        stock_quantity: 100
      )
    end

    describe 'GET #show' do
      it 'returns the product' do
        get :show, params: { id: product.id }, format: :json
        json = JSON.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect(json['data']['name']).to eq('Test Product')
        expect(json['data']['price']).to eq('99.99')
      end

      it 'returns 404 for non-existing product' do
        get :show, params: { id: 999_999 }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST #create' do
      let(:valid_params) do
        {
          product: {
            name: 'New Product',
            sku: 'NEW-001',
            price: 49.99,
            category: 'clothing',
            active: true,
            stock_quantity: 50
          }
        }
      end

      it 'creates a new product' do
        expect do
          post :create, params: valid_params, format: :json
        end.to change(Product, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns validation error for invalid params' do
        post :create, params: { product: { name: '', price: -10 } }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'PUT #update' do
      it 'updates the product' do
        put :update, params: { id: product.id, product: { name: 'Updated Name' } }, format: :json

        expect(response).to have_http_status(:ok)
        expect(product.reload.name).to eq('Updated Name')
      end
    end

    describe 'DELETE #destroy' do
      it 'deletes the product' do
        expect do
          delete :destroy, params: { id: product.id }, format: :json
        end.to change(Product, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
