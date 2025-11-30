# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Controllers::Concerns::CsvSupport do
  let(:controller_class) do
    Class.new do
      include BetterController::Controllers::Concerns::CsvSupport

      attr_accessor :response_body, :response_options

      def send_data(data, options = {})
        @response_body = data
        @response_options = options
      end
    end
  end

  let(:controller) { controller_class.new }

  describe '#generate_csv' do
    context 'with empty collection' do
      it 'returns empty string' do
        expect(controller.generate_csv([])).to eq('')
        expect(controller.generate_csv(nil)).to eq('')
      end
    end

    context 'with hash collection' do
      let(:collection) do
        [
          { id: 1, name: 'Product A', price: 10.99 },
          { id: 2, name: 'Product B', price: 20.50 }
        ]
      end

      it 'generates CSV with auto-detected columns' do
        csv = controller.generate_csv(collection)

        expect(csv).to include('Id,Name,Price')
        expect(csv).to include('1,Product A,10.99')
        expect(csv).to include('2,Product B,20.5')
      end

      it 'generates CSV with specific columns' do
        csv = controller.generate_csv(collection, columns: [:id, :name])

        expect(csv).to include('Id,Name')
        expect(csv).not_to include('Price')
        expect(csv).to include('1,Product A')
      end

      it 'generates CSV with custom headers' do
        csv = controller.generate_csv(
          collection,
          columns: [:id, :name, :price],
          headers: { id: 'ID', name: 'Product Name', price: 'Price (€)' }
        )

        expect(csv).to include('ID,Product Name,Price (€)')
        expect(csv).to include('1,Product A,10.99')
      end
    end

    context 'with model-like objects' do
      let(:model_class) do
        Struct.new(:id, :name, :email, keyword_init: true) do
          def attributes
            { 'id' => id, 'name' => name, 'email' => email }
          end
        end
      end

      let(:collection) do
        [
          model_class.new(id: 1, name: 'John', email: 'john@example.com'),
          model_class.new(id: 2, name: 'Jane', email: 'jane@example.com')
        ]
      end

      it 'generates CSV from model attributes' do
        csv = controller.generate_csv(collection)

        expect(csv).to include('Id,Name,Email')
        expect(csv).to include('1,John,john@example.com')
        expect(csv).to include('2,Jane,jane@example.com')
      end
    end

    context 'with special value types' do
      let(:collection) do
        [
          {
            id: 1,
            created_at: Time.new(2025, 1, 15, 10, 30, 0),
            date: Date.new(2025, 1, 15),
            tags: %w[ruby rails],
            metadata: { key: 'value' }
          }
        ]
      end

      it 'formats Time values' do
        csv = controller.generate_csv(collection, columns: [:created_at])
        expect(csv).to include('2025-01-15 10:30:00')
      end

      it 'formats Date values' do
        csv = controller.generate_csv(collection, columns: [:date])
        expect(csv).to include('2025-01-15')
      end

      it 'formats Array values' do
        csv = controller.generate_csv(collection, columns: [:tags])
        expect(csv).to include('ruby, rails')
      end

      it 'formats Hash values as JSON' do
        csv = controller.generate_csv(collection, columns: [:metadata])
        # CSV escapes quotes, so the JSON is wrapped in quotes with escaped inner quotes
        expect(csv).to include('key')
        expect(csv).to include('value')
      end
    end
  end

  describe '#send_csv' do
    let(:collection) do
      [
        { id: 1, name: 'Product A' },
        { id: 2, name: 'Product B' }
      ]
    end

    it 'sends CSV data with default options' do
      controller.send_csv(collection)

      expect(controller.response_body).to include('Id,Name')
      expect(controller.response_options[:type]).to eq('text/csv; charset=utf-8')
      expect(controller.response_options[:disposition]).to eq('attachment; filename="export.csv"')
    end

    it 'sends CSV data with custom filename' do
      controller.send_csv(collection, filename: 'products.csv')

      expect(controller.response_options[:disposition]).to eq('attachment; filename="products.csv"')
    end

    it 'sends CSV data with specific columns' do
      controller.send_csv(collection, columns: [:name])

      expect(controller.response_body).to include('Name')
      expect(controller.response_body).not_to include('Id')
    end

    it 'sends CSV data with custom headers' do
      controller.send_csv(
        collection,
        headers: { id: 'ID', name: 'Product Name' }
      )

      expect(controller.response_body).to include('ID,Product Name')
    end
  end
end
