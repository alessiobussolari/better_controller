# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
  describe 'GET #index' do
    before do
      User.create!(name: 'John Doe', email: 'john@example.com')
      User.create!(name: 'Jane Doe', email: 'jane@example.com')
    end

    it 'returns success' do
      get :index, format: :json
      expect(response).to have_http_status(:success)
    end

    it 'returns all users' do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(2)
    end

    it 'includes version in meta' do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    it 'returns JSON content type' do
      get :index, format: :json
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #show' do
    let!(:user) { User.create!(name: 'John Doe', email: 'john@example.com') }

    it 'returns success for existing user' do
      get :show, params: { id: user.id }, format: :json
      expect(response).to have_http_status(:success)
    end

    it 'returns the user data' do
      get :show, params: { id: user.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['data']['name']).to eq('John Doe')
      expect(json['data']['email']).to eq('john@example.com')
    end

    it 'includes version in meta' do
      get :show, params: { id: user.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    it 'returns not found for non-existing user' do
      get :show, params: { id: 999_999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns error structure for not found' do
      get :show, params: { id: 999_999 }, format: :json
      json = JSON.parse(response.body)
      expect(json['data']['error']).to be_present
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) { { user: { name: 'New User', email: 'new@example.com' } } }

      it 'creates a new user' do
        expect do
          post :create, params: valid_params, format: :json
        end.to change(User, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params, format: :json
        expect(response).to have_http_status(:created)
      end

      it 'returns the created user' do
        post :create, params: valid_params, format: :json
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq('New User')
        expect(json['data']['email']).to eq('new@example.com')
      end

      it 'includes version in meta' do
        post :create, params: valid_params, format: :json
        json = JSON.parse(response.body)
        expect(json['meta']['version']).to eq('v1')
      end
    end

    context 'with invalid params - missing name' do
      let(:invalid_params) { { user: { name: '', email: 'test@example.com' } } }

      it 'does not create a new user' do
        expect do
          post :create, params: invalid_params, format: :json
        end.not_to change(User, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: invalid_params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error in response' do
        post :create, params: invalid_params, format: :json
        json = JSON.parse(response.body)
        expect(json['data']['error']).to be_present
      end
    end

    context 'with invalid params - missing email' do
      let(:invalid_params) { { user: { name: 'Test', email: '' } } }

      it 'does not create a new user' do
        expect do
          post :create, params: invalid_params, format: :json
        end.not_to change(User, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: invalid_params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with duplicate email' do
      before do
        User.create!(name: 'Existing', email: 'existing@example.com')
      end

      it 'does not create a user with duplicate email' do
        expect do
          post :create, params: { user: { name: 'New', email: 'existing@example.com' } }, format: :json
        end.not_to change(User, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: { user: { name: 'New', email: 'existing@example.com' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    let!(:user) { User.create!(name: 'Original Name', email: 'original@example.com') }

    context 'with valid params' do
      it 'updates the user' do
        put :update, params: { id: user.id, user: { name: 'Updated Name' } }, format: :json
        user.reload
        expect(user.name).to eq('Updated Name')
      end

      it 'returns success status' do
        put :update, params: { id: user.id, user: { name: 'Updated Name' } }, format: :json
        expect(response).to have_http_status(:success)
      end

      it 'returns the updated user' do
        put :update, params: { id: user.id, user: { name: 'Updated Name' } }, format: :json
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq('Updated Name')
      end

      it 'includes version in meta' do
        put :update, params: { id: user.id, user: { name: 'Updated Name' } }, format: :json
        json = JSON.parse(response.body)
        expect(json['meta']['version']).to eq('v1')
      end
    end

    context 'with invalid params' do
      it 'does not update the user with blank name' do
        put :update, params: { id: user.id, user: { name: '' } }, format: :json
        user.reload
        expect(user.name).to eq('Original Name')
      end

      it 'returns unprocessable_entity status' do
        put :update, params: { id: user.id, user: { name: '' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existing user' do
      it 'returns not found' do
        put :update, params: { id: 999_999, user: { name: 'Updated' } }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:user) { User.create!(name: 'To Delete', email: 'delete@example.com') }

    it 'destroys the user' do
      expect do
        delete :destroy, params: { id: user.id }, format: :json
      end.to change(User, :count).by(-1)
    end

    it 'returns success status' do
      delete :destroy, params: { id: user.id }, format: :json
      expect(response).to have_http_status(:success)
    end

    it 'returns deleted confirmation' do
      delete :destroy, params: { id: user.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['data']['deleted']).to be true
    end

    it 'includes version in meta' do
      delete :destroy, params: { id: user.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    context 'with non-existing user' do
      it 'returns not found' do
        delete :destroy, params: { id: 999_999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
