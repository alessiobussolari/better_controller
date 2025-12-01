# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TasksController, type: :controller do
  describe 'GET #index' do
    before do
      Task.create!(title: 'Task 1', description: 'Description 1', status: 'pending')
      Task.create!(title: 'Task 2', description: 'Description 2', status: 'completed')
    end

    it 'returns success for HTML format' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'returns all tasks for HTML format' do
      get :index
      json = JSON.parse(response.body)
      expect(json['tasks'].length).to eq(2)
    end

    it 'returns success for JSON format' do
      get :index, format: :json
      expect(response).to have_http_status(:success)
    end

    it 'returns all tasks for JSON format' do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(2)
    end

    it 'includes version in meta for JSON format' do
      get :index, format: :json
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end
  end

  describe 'GET #show' do
    let!(:task) { Task.create!(title: 'Test Task', description: 'Test description', status: 'pending') }

    it 'returns success for existing task' do
      get :show, params: { id: task.id }
      expect(response).to have_http_status(:success)
    end

    it 'returns the task data for HTML format' do
      get :show, params: { id: task.id }
      json = JSON.parse(response.body)
      expect(json['task']['title']).to eq('Test Task')
    end

    it 'returns the task data for JSON format' do
      get :show, params: { id: task.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['data']['title']).to eq('Test Task')
    end

    it 'includes version in meta for JSON format' do
      get :show, params: { id: task.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    it 'returns not found for non-existing task' do
      get :show, params: { id: 999_999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns error message for not found' do
      get :show, params: { id: 999_999 }
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Task not found')
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) { { task: { title: 'New Task', description: 'New description', status: 'pending' } } }

      it 'creates a new task' do
        expect do
          post :create, params: valid_params
        end.to change(Task, :count).by(1)
      end

      it 'returns created status for HTML format' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns the created task for HTML format' do
        post :create, params: valid_params
        json = JSON.parse(response.body)
        expect(json['task']['title']).to eq('New Task')
      end

      it 'returns created status for JSON format' do
        post :create, params: valid_params, format: :json
        expect(response).to have_http_status(:created)
      end

      it 'returns the created task for JSON format' do
        post :create, params: valid_params, format: :json
        json = JSON.parse(response.body)
        expect(json['data']['title']).to eq('New Task')
      end

      it 'includes version in meta for JSON format' do
        post :create, params: valid_params, format: :json
        json = JSON.parse(response.body)
        expect(json['meta']['version']).to eq('v1')
      end

      it 'creates task with default pending status' do
        post :create, params: { task: { title: 'Task without status', description: 'Desc' } }
        expect(Task.last.status).to eq('pending')
      end
    end

    context 'with invalid params - missing title' do
      let(:invalid_params) { { task: { title: '', description: 'Description', status: 'pending' } } }

      it 'does not create a new task' do
        expect do
          post :create, params: invalid_params
        end.not_to change(Task, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns errors in response' do
        post :create, params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'with invalid params - invalid status' do
      let(:invalid_params) { { task: { title: 'Task', description: 'Desc', status: 'invalid_status' } } }

      it 'does not create a new task' do
        expect do
          post :create, params: invalid_params
        end.not_to change(Task, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    let!(:task) { Task.create!(title: 'Original Title', description: 'Original description', status: 'pending') }

    context 'with valid params' do
      it 'updates the task' do
        put :update, params: { id: task.id, task: { title: 'Updated Title' } }
        task.reload
        expect(task.title).to eq('Updated Title')
      end

      it 'returns success status' do
        put :update, params: { id: task.id, task: { title: 'Updated Title' } }
        expect(response).to have_http_status(:success)
      end

      it 'returns the updated task for HTML format' do
        put :update, params: { id: task.id, task: { title: 'Updated Title' } }
        json = JSON.parse(response.body)
        expect(json['task']['title']).to eq('Updated Title')
      end

      it 'returns the updated task for JSON format' do
        put :update, params: { id: task.id, task: { title: 'Updated Title' } }, format: :json
        json = JSON.parse(response.body)
        expect(json['data']['title']).to eq('Updated Title')
      end

      it 'updates the status' do
        put :update, params: { id: task.id, task: { status: 'completed' } }
        task.reload
        expect(task.status).to eq('completed')
      end
    end

    context 'with invalid params' do
      it 'does not update the task with blank title' do
        put :update, params: { id: task.id, task: { title: '' } }
        task.reload
        expect(task.title).to eq('Original Title')
      end

      it 'returns unprocessable_entity status' do
        put :update, params: { id: task.id, task: { title: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existing task' do
      it 'returns not found' do
        put :update, params: { id: 999_999, task: { title: 'Updated' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:task) { Task.create!(title: 'To Delete', description: 'Delete me', status: 'pending') }

    it 'destroys the task' do
      expect do
        delete :destroy, params: { id: task.id }
      end.to change(Task, :count).by(-1)
    end

    it 'returns success status' do
      delete :destroy, params: { id: task.id }
      expect(response).to have_http_status(:success)
    end

    it 'returns deleted confirmation for HTML format' do
      delete :destroy, params: { id: task.id }
      json = JSON.parse(response.body)
      expect(json['deleted']).to be true
    end

    it 'returns deleted confirmation for JSON format' do
      delete :destroy, params: { id: task.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['data']['deleted']).to be true
    end

    context 'with non-existing task' do
      it 'returns not found' do
        delete :destroy, params: { id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #complete' do
    let!(:task) { Task.create!(title: 'Incomplete Task', description: 'Complete me', status: 'pending') }

    it 'completes the task' do
      post :complete, params: { id: task.id }
      task.reload
      expect(task.status).to eq('completed')
    end

    it 'returns success status' do
      post :complete, params: { id: task.id }
      expect(response).to have_http_status(:success)
    end

    it 'returns the completed task for HTML format' do
      post :complete, params: { id: task.id }
      json = JSON.parse(response.body)
      expect(json['task']['status']).to eq('completed')
    end

    it 'returns the completed task for JSON format' do
      post :complete, params: { id: task.id }, format: :json
      json = JSON.parse(response.body)
      expect(json['data']['status']).to eq('completed')
    end

    context 'with non-existing task' do
      it 'returns not found' do
        post :complete, params: { id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
