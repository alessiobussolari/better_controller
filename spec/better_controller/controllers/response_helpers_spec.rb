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

  before { BetterController.reset_config! }
  after { BetterController.reset_config! }

  describe '#respond_with_success' do
    it 'returns success response with data and meta containing version' do
      controller.respond_with_success({ id: 1, name: 'Test' })

      expect(controller.rendered[:json][:data]).to eq({ id: 1, name: 'Test' })
      expect(controller.rendered[:json][:meta]).to include(version: 'v1')
    end

    it 'uses :ok status by default' do
      controller.respond_with_success('data')

      expect(controller.rendered[:status]).to eq(:ok)
    end

    it 'accepts custom status' do
      controller.respond_with_success('data', status: :created)

      expect(controller.rendered[:status]).to eq(:created)
    end

    it 'merges additional meta' do
      controller.respond_with_success('data', meta: { count: 5 })

      expect(controller.rendered[:json][:meta][:count]).to eq(5)
      expect(controller.rendered[:json][:meta][:version]).to eq('v1')
    end

    it 'handles nil data' do
      controller.respond_with_success(nil)

      expect(controller.rendered[:json][:data]).to be_nil
      expect(controller.rendered[:json][:meta][:version]).to eq('v1')
    end

    it 'uses custom api_version from configuration' do
      BetterController.config.api_version = 'v2'
      controller.respond_with_success('data')

      expect(controller.rendered[:json][:meta][:version]).to eq('v2')
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

        expect(result[:data]).to eq({ id: 1 })
        expect(result[:meta][:version]).to eq('v1')
      end
    end
  end

  describe '#respond_with_error' do
    it 'returns error response with data containing error and meta' do
      controller.respond_with_error('Something went wrong')

      expect(controller.rendered[:json][:data][:error][:message]).to eq('Something went wrong')
      expect(controller.rendered[:json][:meta][:version]).to eq('v1')
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

      expect(controller.rendered[:json][:data][:error][:type]).to eq('StandardError')
      expect(controller.rendered[:json][:data][:error][:message]).to eq('Test error')
    end

    it 'handles custom exception classes' do
      error = ArgumentError.new('Invalid argument')
      controller.respond_with_error(error)

      expect(controller.rendered[:json][:data][:error][:type]).to eq('ArgumentError')
      expect(controller.rendered[:json][:data][:error][:message]).to eq('Invalid argument')
    end

    it 'handles Hash errors' do
      controller.respond_with_error({ code: 'ERR_001', message: 'Custom error' })

      expect(controller.rendered[:json][:data][:error]).to eq({ code: 'ERR_001', message: 'Custom error' })
    end

    it 'merges additional meta' do
      controller.respond_with_error('Error', meta: { request_id: 'abc123' })

      expect(controller.rendered[:json][:meta][:request_id]).to eq('abc123')
      expect(controller.rendered[:json][:meta][:version]).to eq('v1')
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

        expect(result[:data][:error][:message]).to eq('Failed')
        expect(result[:meta][:version]).to eq('v1')
      end
    end

    context 'with ActiveModel-like errors' do
      let(:errors_object) do
        obj = Object.new
        def obj.full_messages
          ['Name is required', 'Email is invalid']
        end

        def obj.to_hash
          { name: ['is required'], email: ['is invalid'] }
        end
        obj
      end

      it 'formats ActiveModel-like errors' do
        controller.respond_with_error(errors_object)

        error = controller.rendered[:json][:data][:error]
        expect(error[:messages]).to eq(['Name is required', 'Email is invalid'])
        expect(error[:details]).to eq({ name: ['is required'], email: ['is invalid'] })
      end
    end
  end

  describe '#build_response (private)' do
    it 'builds standard response structure' do
      response = controller.send(:build_response, { id: 1 }, { extra: 'info' })

      expect(response[:data]).to eq({ id: 1 })
      expect(response[:meta][:version]).to eq('v1')
      expect(response[:meta][:extra]).to eq('info')
    end
  end

  describe '#format_error (private)' do
    it 'formats Exception' do
      error = StandardError.new('Test')
      result = controller.send(:format_error, error)

      expect(result).to eq({ type: 'StandardError', message: 'Test' })
    end

    it 'formats String' do
      result = controller.send(:format_error, 'Error message')

      expect(result).to eq({ message: 'Error message' })
    end

    it 'formats Hash' do
      result = controller.send(:format_error, { code: 'E001' })

      expect(result).to eq({ code: 'E001' })
    end

    it 'formats object with to_hash' do
      obj = OpenStruct.new(to_hash: { field: ['error'] })
      result = controller.send(:format_error, obj)

      expect(result).to eq({ field: ['error'] })
    end

    it 'formats unknown object as string' do
      result = controller.send(:format_error, 12_345)

      expect(result).to eq({ message: '12345' })
    end
  end

  describe 'edge cases' do
    describe '#respond_with_success with complex data' do
      it 'handles array data' do
        controller.respond_with_success([{ id: 1 }, { id: 2 }])

        expect(controller.rendered[:json][:data]).to eq([{ id: 1 }, { id: 2 }])
      end

      it 'handles empty hash data' do
        controller.respond_with_success({})

        expect(controller.rendered[:json][:data]).to eq({})
      end

      it 'handles empty array data' do
        controller.respond_with_success([])

        expect(controller.rendered[:json][:data]).to eq([])
      end

      it 'handles deeply nested data' do
        data = { user: { profile: { settings: { theme: 'dark' } } } }
        controller.respond_with_success(data)

        expect(controller.rendered[:json][:data][:user][:profile][:settings][:theme]).to eq('dark')
      end

      it 'handles data with special characters' do
        data = { message: 'Hello "World" & <Friends>' }
        controller.respond_with_success(data)

        expect(controller.rendered[:json][:data][:message]).to eq('Hello "World" & <Friends>')
      end

      it 'handles data with unicode characters' do
        data = { message: 'Café ☕ émoji 🎉' }
        controller.respond_with_success(data)

        expect(controller.rendered[:json][:data][:message]).to eq('Café ☕ émoji 🎉')
      end

      it 'handles boolean data' do
        controller.respond_with_success(true)

        expect(controller.rendered[:json][:data]).to be true
      end

      it 'handles numeric data' do
        controller.respond_with_success(42)

        expect(controller.rendered[:json][:data]).to eq(42)
      end

      it 'handles string data' do
        controller.respond_with_success('simple string')

        expect(controller.rendered[:json][:data]).to eq('simple string')
      end
    end

    describe '#respond_with_error with edge cases' do
      it 'handles empty string error' do
        controller.respond_with_error('')

        expect(controller.rendered[:json][:data][:error][:message]).to eq('')
      end

      it 'handles nil error' do
        controller.respond_with_error(nil)

        expect(controller.rendered[:json][:data][:error][:message]).to eq('')
      end

      it 'handles empty hash error' do
        controller.respond_with_error({})

        expect(controller.rendered[:json][:data][:error]).to eq({})
      end

      it 'handles RuntimeError' do
        error = RuntimeError.new('Runtime issue')
        controller.respond_with_error(error)

        expect(controller.rendered[:json][:data][:error][:type]).to eq('RuntimeError')
        expect(controller.rendered[:json][:data][:error][:message]).to eq('Runtime issue')
      end

      it 'handles Exception with empty message' do
        error = StandardError.new
        controller.respond_with_error(error)

        expect(controller.rendered[:json][:data][:error][:type]).to eq('StandardError')
        expect(controller.rendered[:json][:data][:error][:message]).to eq('StandardError')
      end

      it 'handles array error' do
        controller.respond_with_error(['Error 1', 'Error 2'])

        expect(controller.rendered[:json][:data][:error][:message]).to eq('["Error 1", "Error 2"]')
      end

      it 'handles symbol error' do
        controller.respond_with_error(:not_found)

        expect(controller.rendered[:json][:data][:error][:message]).to eq('not_found')
      end
    end

    describe 'HTTP status codes' do
      it 'accepts numeric status codes' do
        controller.respond_with_success('data', status: 201)

        expect(controller.rendered[:status]).to eq(201)
      end

      it 'accepts common error statuses' do
        %i[bad_request unauthorized forbidden not_found internal_server_error].each do |status|
          controller.respond_with_error('Error', status: status)

          expect(controller.rendered[:status]).to eq(status)
        end
      end
    end

    describe 'meta options edge cases' do
      it 'handles empty meta hash' do
        controller.respond_with_success('data', meta: {})

        expect(controller.rendered[:json][:meta][:version]).to eq('v1')
      end

      it 'handles meta with nested data' do
        controller.respond_with_success('data', meta: { pagination: { page: 1, total: 100 } })

        expect(controller.rendered[:json][:meta][:pagination]).to eq({ page: 1, total: 100 })
      end

      it 'does not override version with custom meta' do
        controller.respond_with_success('data', meta: { version: 'custom' })

        # Version should be overridden by the passed meta
        expect(controller.rendered[:json][:meta][:version]).to eq('custom')
      end
    end
  end
end
