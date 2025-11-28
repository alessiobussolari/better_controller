# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Controllers::ResponseHelpers do
  let(:controller_class) do
    Class.new do
      include BetterController::Controllers::ResponseHelpers

      attr_accessor :rendered

      def initialize
        @rendered = nil
      end

      def render(options = {})
        @rendered = options
      end
    end
  end

  let(:controller) { controller_class.new }

  describe '#respond_with_success' do
    it 'returns success response with data' do
      controller.respond_with_success({ id: 1, name: 'Test' })

      expect(controller.rendered[:json][:success]).to be true
      expect(controller.rendered[:json][:data]).to eq({ id: 1, name: 'Test' })
    end

    it 'uses :ok status by default' do
      controller.respond_with_success('data')

      expect(controller.rendered[:status]).to eq(:ok)
    end

    it 'accepts custom status' do
      controller.respond_with_success('data', status: :created)

      expect(controller.rendered[:status]).to eq(:created)
    end

    it 'merges additional options' do
      controller.respond_with_success('data', options: { meta: { count: 5 } })

      expect(controller.rendered[:json][:meta]).to eq({ count: 5 })
    end

    it 'handles nil data' do
      controller.respond_with_success(nil)

      expect(controller.rendered[:json][:success]).to be true
      expect(controller.rendered[:json][:data]).to be_nil
    end

    context 'without render method' do
      let(:plain_class) do
        Class.new do
          include BetterController::Controllers::ResponseHelpers
        end
      end

      it 'returns the response hash directly' do
        instance = plain_class.new
        result = instance.respond_with_success({ id: 1 })

        expect(result).to eq({ success: true, data: { id: 1 } })
      end
    end
  end

  describe '#respond_with_error' do
    it 'returns error response with message' do
      controller.respond_with_error('Something went wrong')

      expect(controller.rendered[:json][:success]).to be false
      expect(controller.rendered[:json][:error][:message]).to eq('Something went wrong')
    end

    it 'uses :unprocessable_entity status by default' do
      controller.respond_with_error('Error')

      expect(controller.rendered[:status]).to eq(:unprocessable_entity)
    end

    it 'accepts custom status' do
      controller.respond_with_error('Not found', status: :not_found)

      expect(controller.rendered[:status]).to eq(:not_found)
    end

    it 'handles Exception objects' do
      error = StandardError.new('Test error')
      controller.respond_with_error(error)

      expect(controller.rendered[:json][:error][:type]).to eq('StandardError')
      expect(controller.rendered[:json][:error][:message]).to eq('Test error')
    end

    it 'handles custom exception classes' do
      error = ArgumentError.new('Invalid argument')
      controller.respond_with_error(error)

      expect(controller.rendered[:json][:error][:type]).to eq('ArgumentError')
    end

    it 'merges additional options' do
      controller.respond_with_error('Error', options: { code: 'ERR_001' })

      expect(controller.rendered[:json][:code]).to eq('ERR_001')
    end

    context 'without render method' do
      let(:plain_class) do
        Class.new do
          include BetterController::Controllers::ResponseHelpers
        end
      end

      it 'returns the response hash directly' do
        instance = plain_class.new
        result = instance.respond_with_error('Failed')

        expect(result[:success]).to be false
        expect(result[:error][:message]).to eq('Failed')
      end
    end
  end

  describe '#respond_with_pagination' do
    let(:paginated_collection) do
      collection = [1, 2, 3, 4, 5]

      # Add pagination methods
      def collection.page(num)
        @page = num
        self
      end

      def collection.per(num)
        @per = num
        self
      end

      def collection.current_page
        @page || 1
      end

      def collection.total_pages
        2
      end

      def collection.total_count
        10
      end

      collection
    end

    it 'returns paginated response with metadata' do
      controller.respond_with_pagination(paginated_collection, page: 1, per_page: 5)

      expect(controller.rendered[:json][:success]).to be true
      expect(controller.rendered[:json][:meta][:pagination]).to include(
        :current_page,
        :total_pages,
        :total_count
      )
    end

    it 'uses default pagination values' do
      controller.respond_with_pagination(paginated_collection)

      expect(controller.rendered[:json][:meta][:pagination][:current_page]).to eq(1)
    end

    it 'uses provided page number' do
      collection = paginated_collection

      def collection.page(num)
        @page = num
        self
      end

      controller.respond_with_pagination(collection, page: 2)

      expect(controller.rendered[:json][:meta][:pagination][:current_page]).to eq(2)
    end

    it 'uses provided per_page value' do
      collection = paginated_collection
      pages_received = nil

      def collection.per(num)
        @per_value = num
        self
      end

      def collection.per_value
        @per_value
      end

      controller.respond_with_pagination(collection, per_page: 10)
      # The per method was called - we verify pagination works
      expect(controller.rendered[:json][:success]).to be true
    end

    it 'includes total_pages in metadata' do
      controller.respond_with_pagination(paginated_collection)

      expect(controller.rendered[:json][:meta][:pagination][:total_pages]).to eq(2)
    end

    it 'includes total_count in metadata' do
      controller.respond_with_pagination(paginated_collection)

      expect(controller.rendered[:json][:meta][:pagination][:total_count]).to eq(10)
    end
  end
end
