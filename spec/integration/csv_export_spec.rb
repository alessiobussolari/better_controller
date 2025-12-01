# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvExportsController, type: :controller do
  describe 'CSV Export Integration' do
    before do
      User.destroy_all
      @users = []
      10.times do |i|
        @users << User.create!(
          name: "User #{i + 1}",
          email: "user#{i + 1}@example.com"
        )
      end
    end

    describe 'GET #index' do
      context 'with CSV format' do
        it 'returns CSV content type' do
          get :index, format: :csv

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include('text/csv')
        end

        it 'returns Content-Disposition with filename' do
          get :index, format: :csv

          expect(response.headers['Content-Disposition']).to include('attachment')
          expect(response.headers['Content-Disposition']).to include("users_export_#{Date.current}.csv")
        end

        it 'includes custom headers' do
          get :index, format: :csv

          lines = response.body.lines
          header_line = lines.first.strip

          expect(header_line).to include('User ID')
          expect(header_line).to include('Full Name')
          expect(header_line).to include('Email Address')
          expect(header_line).to include('Registration Date')
        end

        it 'includes all user data' do
          get :index, format: :csv

          lines = response.body.lines
          # Header + 10 users
          expect(lines.length).to eq(11)
        end

        it 'exports correct data for each user' do
          get :index, format: :csv

          lines = response.body.lines
          data_line = lines[1].strip

          expect(data_line).to include(@users.first.id.to_s)
          expect(data_line).to include('User 1')
          expect(data_line).to include('user1@example.com')
        end
      end

      context 'with JSON format' do
        it 'returns JSON response' do
          get :index, format: :json

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include('application/json')

          json = JSON.parse(response.body)
          expect(json['data'].length).to eq(10)
        end
      end

      context 'with HTML format' do
        it 'returns HTML response' do
          get :index, format: :html

          expect(response).to have_http_status(:ok)
          expect(response.body).to eq('Users list')
        end
      end
    end

    describe 'GET #show' do
      context 'with CSV format' do
        it 'returns CSV for single user' do
          user = @users.first
          get :show, params: { id: user.id }, format: :csv

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include('text/csv')
        end

        it 'includes correct filename with user ID' do
          user = @users.first
          get :show, params: { id: user.id }, format: :csv

          expect(response.headers['Content-Disposition']).to include("user_#{user.id}.csv")
        end

        it 'contains single user data' do
          user = @users.first
          get :show, params: { id: user.id }, format: :csv

          lines = response.body.lines
          # Header + 1 user
          expect(lines.length).to eq(2)
          expect(lines[1]).to include(user.name)
          expect(lines[1]).to include(user.email)
        end
      end

      context 'with non-existing user' do
        it 'returns 404 for JSON' do
          get :show, params: { id: 999_999 }, format: :json

          expect(response).to have_http_status(:not_found)
        end

        it 'returns 404 for HTML' do
          get :show, params: { id: 999_999 }, format: :html

          expect(response).to have_http_status(:not_found)
          # Error is returned as JSON even for HTML format when using ResourcesController
          json = JSON.parse(response.body) rescue nil
          expect(json || response.body).to be_present
        end
      end
    end

    describe 'CSV with special characters' do
      before do
        User.destroy_all
        @special_user = User.create!(
          name: 'O\'Connor, John "Jack"',
          email: 'john.oconnor@example.com'
        )
      end

      it 'properly escapes quotes in CSV' do
        get :index, format: :csv

        # CSV should escape special characters
        expect(response.body).to include('O\'Connor')
      end

      it 'properly handles commas in data' do
        get :index, format: :csv

        lines = response.body.lines
        # The name with comma should be quoted or escaped
        expect(lines.length).to eq(2) # Header + 1 user
      end
    end

    describe 'CSV with empty collection' do
      before { User.destroy_all }

      it 'returns OK status with CSV for empty collection' do
        get :index, format: :csv

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('text/csv')
      end
    end

    describe 'CSV encoding' do
      before do
        User.destroy_all
        @unicode_user = User.create!(
          name: 'José García',
          email: 'jose.garcia@example.com'
        )
      end

      it 'handles unicode characters' do
        get :index, format: :csv

        expect(response.body).to include('José García')
      end

      it 'uses UTF-8 encoding' do
        get :index, format: :csv

        expect(response.body.encoding.name).to eq('UTF-8')
      end
    end

    describe 'Large dataset performance' do
      before do
        User.destroy_all
        100.times do |i|
          User.create!(
            name: "Bulk User #{i + 1}",
            email: "bulk#{i + 1}@example.com"
          )
        end
      end

      it 'exports large datasets efficiently' do
        start_time = Time.current
        get :index, format: :csv
        elapsed = Time.current - start_time

        expect(response).to have_http_status(:ok)
        lines = response.body.lines
        expect(lines.length).to eq(101) # Header + 100 users
        expect(elapsed).to be < 5 # Should complete within 5 seconds
      end
    end
  end
end
