# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Requests', type: :request do
  describe 'Products API' do
    let!(:products) do
      3.times.map do |i|
        Product.create!(
          name: "Product #{i + 1}",
          sku: "SKU-#{format('%03d', i + 1)}",
          price: (10.0 + i).round(2),
          category: %w[electronics clothing food][i % 3],
          active: true,
          stock_quantity: 100
        )
      end
    end

    describe 'GET /products' do
      it 'returns a list of products' do
        get '/products', headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
      end

      it 'includes meta information' do
        get '/products', headers: { 'Accept' => 'application/json' }

        json = JSON.parse(response.body)
        expect(json['meta']).to be_present
        expect(json['meta']['version']).to eq('v1')
      end
    end

    describe 'GET /products/:id' do
      it 'returns a single product' do
        product = products.first
        get "/products/#{product.id}", headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq(product.name)
      end

      it 'returns 404 for non-existing product' do
        get '/products/999999', headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Tasks API' do
    let!(:task) do
      Task.create!(
        title: 'Test Task',
        description: 'A test task',
        status: 'pending',
        priority: 1
      )
    end

    describe 'GET /tasks' do
      it 'returns tasks list' do
        get '/tasks', headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
      end
    end

    describe 'GET /tasks/:id' do
      it 'returns a single task' do
        get "/tasks/#{task.id}", headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['title']).to eq('Test Task')
      end
    end

    describe 'POST /tasks' do
      let(:valid_params) do
        {
          task: {
            title: 'New Task',
            description: 'New description',
            status: 'pending',
            priority: 2
          }
        }
      end

      it 'creates a new task' do
        expect do
          post '/tasks', params: valid_params, headers: { 'Accept' => 'application/json' }
        end.to change(Task, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns the created task' do
        post '/tasks', params: valid_params, headers: { 'Accept' => 'application/json' }

        json = JSON.parse(response.body)
        expect(json['data']['title']).to eq('New Task')
      end

      it 'returns validation errors for invalid params' do
        post '/tasks', params: { task: { title: '' } }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'PUT /tasks/:id' do
      it 'updates the task' do
        put "/tasks/#{task.id}", params: { task: { title: 'Updated Title' } }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        expect(task.reload.title).to eq('Updated Title')
      end

      it 'returns 404 for non-existing task' do
        put '/tasks/999999', params: { task: { title: 'Updated' } }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'DELETE /tasks/:id' do
      it 'deletes the task' do
        expect do
          delete "/tasks/#{task.id}", headers: { 'Accept' => 'application/json' }
        end.to change(Task, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST /tasks/:id/complete' do
      it 'marks the task as completed' do
        post "/tasks/#{task.id}/complete", headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        expect(task.reload.status).to eq('completed')
      end
    end
  end

  describe 'Articles with nested Comments' do
    let!(:article) do
      Article.create!(
        title: 'Test Article',
        body: 'Article body content'
      )
    end

    let!(:comment) do
      Comment.create!(
        article: article,
        body: 'Test comment',
        author: 'Test Author'
      )
    end

    describe 'GET /articles/:article_id/comments' do
      it 'returns comments for an article' do
        get "/articles/#{article.id}/comments", headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
        expect(json['data'].first['body']).to eq('Test comment')
      end
    end

    describe 'POST /articles/:article_id/comments' do
      it 'creates a comment for an article' do
        expect do
          post "/articles/#{article.id}/comments",
               params: { comment: { body: 'New comment', author: 'Author' } },
               headers: { 'Accept' => 'application/json' }
        end.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe 'Examples controller with action DSL' do
    let!(:example) do
      Example.create!(
        name: 'Test Example',
        description: 'Example description',
        status: 'active'
      )
    end

    describe 'GET /examples' do
      it 'returns examples list' do
        get '/examples', headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
      end
    end

    describe 'GET /examples/:id' do
      it 'returns a single example' do
        get "/examples/#{example.id}", headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq('Test Example')
      end
    end
  end

  describe 'API Users namespace' do
    describe 'GET /api/users' do
      before do
        3.times do |i|
          User.create!(name: "API User #{i + 1}", email: "api#{i + 1}@example.com")
        end
      end

      it 'returns users in API namespace' do
        get '/api/users', headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to eq(3)
      end
    end
  end

  describe 'Content negotiation' do
    let!(:product) do
      Product.create!(
        name: 'Content Test Product',
        sku: 'CONTENT-001',
        price: 99.99,
        category: 'electronics',
        active: true,
        stock_quantity: 50
      )
    end

    it 'responds to JSON Accept header' do
      get '/products', headers: { 'Accept' => 'application/json' }

      expect(response.content_type).to include('application/json')
    end

    it 'responds to format parameter' do
      get '/products.json'

      expect(response.content_type).to include('application/json')
    end
  end

  describe 'Error handling' do
    it 'returns 404 JSON for non-existing resource' do
      get '/products/999999', headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      # ResourcesController wraps errors in data.error
      expect(json['data']['error']).to be_present
    end

    it 'returns validation errors as JSON' do
      post '/tasks', params: { task: { title: '', priority: -1 } }, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end
end
