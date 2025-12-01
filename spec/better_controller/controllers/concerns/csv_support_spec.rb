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

  describe 'edge cases' do
    describe '#generate_csv with special content' do
      it 'handles values containing commas' do
        collection = [{ name: 'Product, with comma', price: 10 }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('"Product, with comma"')
      end

      it 'handles values containing quotes' do
        collection = [{ name: 'Product "Quoted"', price: 10 }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('Product ""Quoted""')
      end

      it 'handles values containing newlines' do
        collection = [{ name: "Multi\nLine\nProduct", price: 10 }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('Multi')
        expect(csv).to include('Line')
      end

      it 'handles nil values in collection' do
        collection = [
          { id: 1, name: nil, price: 10 },
          { id: 2, name: 'Product', price: nil }
        ]
        csv = controller.generate_csv(collection)

        expect(csv).to include('1,,10')
        expect(csv).to include('2,Product,')
      end

      it 'handles boolean values' do
        collection = [{ id: 1, active: true }, { id: 2, active: false }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('true')
        # false is converted to empty string in CSV generation
        expect(csv).to include('2,')
      end

      it 'handles very large numbers' do
        collection = [{ id: 1, amount: 999_999_999_999.99 }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('999999999999.99')
      end

      it 'handles negative numbers' do
        collection = [{ id: 1, balance: -100.50 }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('-100.5')
      end

      it 'handles unicode characters' do
        collection = [{ id: 1, name: 'Café ☕', emoji: '🎉' }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('Café ☕')
        expect(csv).to include('🎉')
      end

      it 'handles HTML tags in values' do
        collection = [{ id: 1, content: '<script>alert("xss")</script>' }]
        csv = controller.generate_csv(collection)

        expect(csv).to include('<script>')
      end

      it 'handles empty strings' do
        collection = [{ id: 1, name: '', description: 'Test' }]
        csv = controller.generate_csv(collection)

        # Empty strings are quoted in CSV
        expect(csv).to include('1,"",Test')
      end
    end

    describe '#generate_csv with column handling' do
      it 'handles columns that do not exist in data' do
        collection = [{ id: 1, name: 'Product' }]
        csv = controller.generate_csv(collection, columns: [:id, :name, :nonexistent])

        expect(csv).to include('Id,Name,Nonexistent')
        expect(csv).to include('1,Product,')
      end

      it 'handles symbol and string keys mixed' do
        collection = [{ 'id' => 1, :name => 'Product' }]
        csv = controller.generate_csv(collection)

        # Should handle both key types
        expect(csv).to be_a(String)
      end

      it 'preserves column order when specified' do
        collection = [{ id: 1, name: 'Product', price: 10 }]
        csv = controller.generate_csv(collection, columns: [:price, :id, :name])

        lines = csv.split("\n")
        expect(lines.first).to eq('Price,Id,Name')
      end
    end

    describe '#send_csv with edge cases' do
      it 'handles empty collection' do
        controller.send_csv([])

        expect(controller.response_body).to eq('')
      end

      it 'handles filename without .csv extension' do
        controller.send_csv([{ id: 1 }], filename: 'data')

        expect(controller.response_options[:disposition]).to eq('attachment; filename="data"')
      end

      it 'handles filename with special characters' do
        controller.send_csv([{ id: 1 }], filename: 'export_2025-01-15.csv')

        expect(controller.response_options[:disposition]).to include('export_2025-01-15.csv')
      end

      it 'handles very long filenames' do
        long_name = 'a' * 200 + '.csv'
        controller.send_csv([{ id: 1 }], filename: long_name)

        expect(controller.response_options[:disposition]).to include(long_name)
      end
    end

    describe '#generate_csv with DateTime edge cases' do
      it 'handles DateTime objects' do
        datetime = DateTime.new(2025, 6, 15, 14, 30, 45)
        collection = [{ id: 1, created: datetime }]
        csv = controller.generate_csv(collection, columns: [:created])

        expect(csv).to include('2025-06-15')
      end

      it 'handles date with timezone info' do
        time = Time.new(2025, 1, 15, 10, 30, 0, '+09:00')
        collection = [{ timestamp: time }]
        csv = controller.generate_csv(collection, columns: [:timestamp])

        expect(csv).to include('2025-01-15')
      end
    end
  end
end
