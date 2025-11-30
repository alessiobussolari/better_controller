# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  describe 'Turbo Frame requests' do
    describe 'GET #index with Turbo-Frame header' do
      before do
        request.headers['Turbo-Frame'] = 'products_frame'
        request.accept = 'text/html'
      end

      it 'returns HTTP success' do
        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'detects turbo_frame_request? as true' do
        get :index

        expect(controller.send(:turbo_frame_request?)).to be true
      end

      it 'returns the correct Turbo Frame ID' do
        get :index

        expect(controller.send(:current_turbo_frame)).to eq('products_frame')
      end
    end

    describe 'GET #index without Turbo-Frame header' do
      before do
        request.accept = 'text/html'
      end

      it 'detects turbo_frame_request? as false' do
        get :index

        expect(controller.send(:turbo_frame_request?)).to be false
      end

      it 'returns nil for current_turbo_frame' do
        get :index

        expect(controller.send(:current_turbo_frame)).to be_nil
      end
    end
  end

  describe 'Turbo Stream responses' do
    describe 'GET #index with Turbo Stream format' do
      before do
        request.accept = 'text/vnd.turbo-stream.html'
      end

      it 'returns turbo stream content type' do
        get :index

        expect(response.content_type).to include('text/vnd.turbo-stream.html')
      end

      it 'includes turbo-stream tags in response' do
        get :index

        expect(response.body).to include('turbo-stream')
      end

      it 'detects turbo_stream_request? as true' do
        get :index

        expect(controller.send(:turbo_stream_request?)).to be true
      end
    end

    describe 'GET #index with HTML format' do
      before do
        request.accept = 'text/html'
      end

      it 'detects turbo_stream_request? as false' do
        get :index

        expect(controller.send(:turbo_stream_request?)).to be false
      end
    end
  end

  describe 'Turbo Native app detection' do
    describe 'with Turbo Native user agent' do
      before do
        request.headers['User-Agent'] = 'Turbo Native iOS'
        request.accept = 'text/html'
      end

      it 'detects turbo_native_app? as true' do
        get :index

        expect(controller.send(:turbo_native_app?)).to be true
      end
    end

    describe 'without Turbo Native user agent' do
      before do
        request.headers['User-Agent'] = 'Mozilla/5.0'
        request.accept = 'text/html'
      end

      it 'detects turbo_native_app? as false' do
        get :index

        expect(controller.send(:turbo_native_app?)).to be false
      end
    end
  end
end
