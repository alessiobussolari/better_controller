# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActionDslProductsController, type: :controller do
  describe 'GET #index' do
    describe 'JSON format' do
      it 'returns JSON response' do
        request.accept = 'application/json'
        get :index

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to eq(3)
        expect(json['meta']['format']).to eq('json')
      end

      it 'returns correct product data' do
        request.accept = 'application/json'
        get :index

        json = JSON.parse(response.body)
        first_product = json['data'].first
        expect(first_product['id']).to eq(1)
        expect(first_product['name']).to eq('Product A')
        expect(first_product['price']).to eq(10.99)
      end
    end

    describe 'HTML format' do
      it 'returns HTML response' do
        request.accept = 'text/html'
        get :index

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('HTML Index')
      end
    end

    describe 'Turbo Stream format' do
      it 'returns Turbo Stream response' do
        request.accept = 'text/vnd.turbo-stream.html'
        get :index

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/vnd.turbo-stream.html')
        expect(response.body).to include('turbo-stream')
        expect(response.body).to include('action="replace"')
        expect(response.body).to include('target="products"')
      end
    end

    describe 'CSV format' do
      it 'returns CSV response with correct headers' do
        request.accept = 'text/csv'
        get :index

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
        expect(response.headers['Content-Disposition']).to include('products.csv')
      end

      it 'returns CSV with correct data structure' do
        request.accept = 'text/csv'
        get :index

        csv_lines = response.body.split("\n")
        expect(csv_lines.first).to include('Id', 'Name', 'Price')
        expect(csv_lines.length).to eq(4) # header + 3 products
      end

      it 'includes all products in CSV' do
        request.accept = 'text/csv'
        get :index

        expect(response.body).to include('Product A')
        expect(response.body).to include('Product B')
        expect(response.body).to include('Product C')
      end
    end

    describe 'XML format' do
      it 'returns XML response' do
        request.accept = 'application/xml'
        get :index

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/xml')
      end

      it 'returns valid XML structure' do
        request.accept = 'application/xml'
        get :index

        expect(response.body).to include('<?xml')
        expect(response.body).to include('Product A')
        expect(response.body).to include('Product B')
        expect(response.body).to include('Product C')
      end
    end
  end

  describe 'GET #show' do
    describe 'with valid ID' do
      describe 'JSON format' do
        it 'returns resource as JSON' do
          request.accept = 'application/json'
          get :show, params: { id: 1 }

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include('application/json')

          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(1)
          expect(json['data']['name']).to eq('Product 1')
          expect(json['data']['price']).to eq(29.99)
        end

        it 'includes format in meta' do
          request.accept = 'application/json'
          get :show, params: { id: 1 }

          json = JSON.parse(response.body)
          expect(json['meta']['format']).to eq('json')
        end
      end

      describe 'HTML format' do
        it 'returns HTML response' do
          request.accept = 'text/html'
          get :show, params: { id: 1 }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('HTML Show')
          expect(response.body).to include('Product 1')
        end
      end

      describe 'CSV format' do
        it 'returns resource as CSV' do
          request.accept = 'text/csv'
          get :show, params: { id: 1 }

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include('text/csv')
          expect(response.headers['Content-Disposition']).to include('product.csv')
        end

        it 'includes product data in CSV' do
          request.accept = 'text/csv'
          get :show, params: { id: 1 }

          expect(response.body).to include('Product 1')
          expect(response.body).to include('29.99')
        end
      end

      describe 'XML format' do
        it 'returns resource as XML' do
          request.accept = 'application/xml'
          get :show, params: { id: 1 }

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include('application/xml')
        end

        it 'includes product data in XML' do
          request.accept = 'application/xml'
          get :show, params: { id: 1 }

          expect(response.body).to include('Product 1')
          expect(response.body).to include('29.99')
        end
      end
    end

    describe 'with invalid ID' do
      describe 'JSON format' do
        it 'returns not found error' do
          request.accept = 'application/json'
          get :show, params: { id: 0 }

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json['error']).to eq('Not found')
        end
      end

      describe 'XML format' do
        it 'returns not found error as XML' do
          request.accept = 'application/xml'
          get :show, params: { id: 0 }

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include('Not found')
        end
      end

      describe 'HTML format' do
        it 'returns not found page' do
          request.accept = 'text/html'
          get :show, params: { id: 0 }

          expect(response).to have_http_status(:not_found)
          expect(response.body).to include('Not Found')
        end
      end

      describe 'CSV format' do
        it 'returns unprocessable entity for errors' do
          request.accept = 'text/csv'
          get :show, params: { id: 0 }

          # CSV doesn't have a custom error handler, so it falls back to default
          # which may return 422 or follow the error flow
          expect(response).to have_http_status(:not_found).or have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'Turbo Frame requests' do
    describe 'GET #index with Turbo-Frame header' do
      it 'responds successfully to Turbo Frame request' do
        request.headers['Turbo-Frame'] = 'products_frame'
        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'controller detects Turbo Frame request' do
        request.headers['Turbo-Frame'] = 'products_frame'
        get :index

        # The turbo_frame_request? helper should be available through TurboSupport
        expect(controller.send(:turbo_frame_request?)).to be true
      end

      it 'controller returns correct current_turbo_frame' do
        request.headers['Turbo-Frame'] = 'products_frame'
        get :index

        expect(controller.send(:current_turbo_frame)).to eq('products_frame')
      end
    end

    describe 'GET #index without Turbo-Frame header' do
      it 'controller detects non-Turbo Frame request' do
        get :index

        expect(controller.send(:turbo_frame_request?)).to be false
      end

      it 'controller returns nil for current_turbo_frame' do
        get :index

        expect(controller.send(:current_turbo_frame)).to be_nil
      end
    end
  end
end
