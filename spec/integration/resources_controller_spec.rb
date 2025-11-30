# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExamplesController, type: :controller do
  describe 'GET #index' do
    before do
      Example.create!(name: 'Example 1', email: 'example1@test.com')
      Example.create!(name: 'Example 2', email: 'example2@test.com')
    end

    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'returns all examples' do
      get :index
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(2)
    end

    it 'includes version in meta' do
      get :index
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end
  end

  describe 'GET #show' do
    let!(:example) { Example.create!(name: 'Test', email: 'test@test.com') }

    it 'returns success for existing resource' do
      get :show, params: { id: example.id }
      expect(response).to have_http_status(:success)
    end

    it 'returns the resource data' do
      get :show, params: { id: example.id }
      json = JSON.parse(response.body)
      expect(json['data']['name']).to eq('Test')
    end

    it 'includes version in meta' do
      get :show, params: { id: example.id }
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    it 'returns not found for non-existing resource' do
      get :show, params: { id: 999_999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new example' do
        expect do
          post :create, params: { example: { name: 'New Example', email: 'new@test.com' } }
        end.to change(Example, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: { example: { name: 'New Example', email: 'new@test.com' } }
        expect(response).to have_http_status(:created)
      end

      it 'returns the created resource' do
        post :create, params: { example: { name: 'New Example', email: 'new@test.com' } }
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq('New Example')
      end

      it 'includes version in meta' do
        post :create, params: { example: { name: 'New Example', email: 'new@test.com' } }
        json = JSON.parse(response.body)
        expect(json['meta']['version']).to eq('v1')
      end
    end

    context 'with invalid params' do
      it 'does not create a new example' do
        expect do
          post :create, params: { example: { name: '', email: 'invalid@test.com' } }
        end.not_to change(Example, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: { example: { name: '', email: 'invalid@test.com' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error in response' do
        post :create, params: { example: { name: '', email: 'invalid@test.com' } }
        json = JSON.parse(response.body)
        expect(json['data']['error']).to be_present
      end
    end
  end

  describe 'PUT #update' do
    let!(:example) { Example.create!(name: 'Original', email: 'original@test.com') }

    context 'with valid params' do
      it 'updates the example' do
        put :update, params: { id: example.id, example: { name: 'Updated' } }
        example.reload
        expect(example.name).to eq('Updated')
      end

      it 'returns success status' do
        put :update, params: { id: example.id, example: { name: 'Updated' } }
        expect(response).to have_http_status(:success)
      end

      it 'includes version in meta' do
        put :update, params: { id: example.id, example: { name: 'Updated' } }
        json = JSON.parse(response.body)
        expect(json['meta']['version']).to eq('v1')
      end
    end

    context 'with invalid params' do
      it 'does not update the example' do
        put :update, params: { id: example.id, example: { name: '' } }
        example.reload
        expect(example.name).to eq('Original')
      end

      it 'returns unprocessable_entity status' do
        put :update, params: { id: example.id, example: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existing resource' do
      it 'returns not found' do
        put :update, params: { id: 999_999, example: { name: 'Updated' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:example) { Example.create!(name: 'To Delete', email: 'delete@test.com') }

    it 'destroys the example' do
      expect do
        delete :destroy, params: { id: example.id }
      end.to change(Example, :count).by(-1)
    end

    it 'returns success status' do
      delete :destroy, params: { id: example.id }
      expect(response).to have_http_status(:success)
    end

    it 'includes version in meta' do
      delete :destroy, params: { id: example.id }
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    context 'with non-existing resource' do
      it 'returns not found' do
        delete :destroy, params: { id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

RSpec.describe ArticlesController, type: :controller do
  describe 'GET #index' do
    before do
      Article.create!(title: 'Article 1', body: 'Body 1')
      Article.create!(title: 'Article 2', body: 'Body 2', published: true)
    end

    it 'returns success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'returns all articles' do
      get :index
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(2)
    end

    it 'includes version in meta' do
      get :index
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end
  end

  describe 'POST #create with all attributes' do
    it 'creates an article with all attributes' do
      post :create, params: { article: { title: 'New Article', body: 'Full body text', published: true } }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('New Article')
      expect(json['data']['published']).to be true
    end
  end
end
