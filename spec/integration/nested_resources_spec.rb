# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let!(:article) { Article.create!(title: 'Test Article', body: 'Test body') }

  describe 'GET #index' do
    before do
      Comment.create!(article: article, author: 'Author 1', body: 'Comment 1')
      Comment.create!(article: article, author: 'Author 2', body: 'Comment 2')
    end

    it 'returns success' do
      get :index, params: { article_id: article.id }
      expect(response).to have_http_status(:success)
    end

    it 'returns comments for the article' do
      get :index, params: { article_id: article.id }
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(2)
    end

    it 'includes version in meta' do
      get :index, params: { article_id: article.id }
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    it 'only returns comments for the specified article' do
      other_article = Article.create!(title: 'Other Article', body: 'Other body')
      Comment.create!(article: other_article, author: 'Other Author', body: 'Other comment')

      get :index, params: { article_id: article.id }
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(2)
    end

    it 'returns not found for non-existing article' do
      get :index, params: { article_id: 999_999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #show' do
    let!(:comment) { Comment.create!(article: article, author: 'Test Author', body: 'Test comment') }

    it 'returns success for existing comment' do
      get :show, params: { article_id: article.id, id: comment.id }
      expect(response).to have_http_status(:success)
    end

    it 'returns the comment data' do
      get :show, params: { article_id: article.id, id: comment.id }
      json = JSON.parse(response.body)
      expect(json['data']['author']).to eq('Test Author')
      expect(json['data']['body']).to eq('Test comment')
    end

    it 'includes version in meta' do
      get :show, params: { article_id: article.id, id: comment.id }
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    it 'returns not found for non-existing comment' do
      get :show, params: { article_id: article.id, id: 999_999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for non-existing article' do
      get :show, params: { article_id: 999_999, id: comment.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) { { comment: { author: 'New Author', body: 'New comment' } } }

      it 'creates a new comment' do
        expect do
          post :create, params: { article_id: article.id }.merge(valid_params)
        end.to change(Comment, :count).by(1)
      end

      it 'associates the comment with the article' do
        post :create, params: { article_id: article.id }.merge(valid_params)
        expect(Comment.last.article).to eq(article)
      end

      it 'returns created status' do
        post :create, params: { article_id: article.id }.merge(valid_params)
        expect(response).to have_http_status(:created)
      end

      it 'returns the created comment' do
        post :create, params: { article_id: article.id }.merge(valid_params)
        json = JSON.parse(response.body)
        expect(json['data']['author']).to eq('New Author')
        expect(json['data']['body']).to eq('New comment')
      end

      it 'includes version in meta' do
        post :create, params: { article_id: article.id }.merge(valid_params)
        json = JSON.parse(response.body)
        expect(json['meta']['version']).to eq('v1')
      end
    end

    context 'with invalid params - missing body' do
      let(:invalid_params) { { comment: { author: 'Author', body: '' } } }

      it 'does not create a new comment' do
        expect do
          post :create, params: { article_id: article.id }.merge(invalid_params)
        end.not_to change(Comment, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: { article_id: article.id }.merge(invalid_params)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid params - missing author' do
      let(:invalid_params) { { comment: { author: '', body: 'Comment body' } } }

      it 'does not create a new comment' do
        expect do
          post :create, params: { article_id: article.id }.merge(invalid_params)
        end.not_to change(Comment, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: { article_id: article.id }.merge(invalid_params)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existing article' do
      it 'returns not found' do
        post :create, params: { article_id: 999_999, comment: { author: 'Author', body: 'Body' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT #update' do
    let!(:comment) { Comment.create!(article: article, author: 'Original Author', body: 'Original body') }

    context 'with valid params' do
      it 'updates the comment' do
        put :update, params: { article_id: article.id, id: comment.id, comment: { body: 'Updated body' } }
        comment.reload
        expect(comment.body).to eq('Updated body')
      end

      it 'returns success status' do
        put :update, params: { article_id: article.id, id: comment.id, comment: { body: 'Updated body' } }
        expect(response).to have_http_status(:success)
      end

      it 'returns the updated comment' do
        put :update, params: { article_id: article.id, id: comment.id, comment: { body: 'Updated body' } }
        json = JSON.parse(response.body)
        expect(json['data']['body']).to eq('Updated body')
      end

      it 'includes version in meta' do
        put :update, params: { article_id: article.id, id: comment.id, comment: { body: 'Updated body' } }
        json = JSON.parse(response.body)
        expect(json['meta']['version']).to eq('v1')
      end
    end

    context 'with invalid params' do
      it 'does not update the comment with blank body' do
        put :update, params: { article_id: article.id, id: comment.id, comment: { body: '' } }
        comment.reload
        expect(comment.body).to eq('Original body')
      end

      it 'returns unprocessable_entity status' do
        put :update, params: { article_id: article.id, id: comment.id, comment: { body: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with non-existing comment' do
      it 'returns not found' do
        put :update, params: { article_id: article.id, id: 999_999, comment: { body: 'Updated' } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with non-existing article' do
      it 'returns not found' do
        put :update, params: { article_id: 999_999, id: comment.id, comment: { body: 'Updated' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:comment) { Comment.create!(article: article, author: 'To Delete', body: 'Delete me') }

    it 'destroys the comment' do
      expect do
        delete :destroy, params: { article_id: article.id, id: comment.id }
      end.to change(Comment, :count).by(-1)
    end

    it 'returns success status' do
      delete :destroy, params: { article_id: article.id, id: comment.id }
      expect(response).to have_http_status(:success)
    end

    it 'includes version in meta' do
      delete :destroy, params: { article_id: article.id, id: comment.id }
      json = JSON.parse(response.body)
      expect(json['meta']['version']).to eq('v1')
    end

    context 'with non-existing comment' do
      it 'returns not found' do
        delete :destroy, params: { article_id: article.id, id: 999_999 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with non-existing article' do
      it 'returns not found' do
        delete :destroy, params: { article_id: 999_999, id: comment.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
