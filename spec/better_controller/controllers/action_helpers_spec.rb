# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe BetterController::Controllers::ActionHelpers do
  # Mock resource class
  let(:resource_class) do
    klass = Class.new do
      def self.name
        'User'
      end

      attr_reader :id, :name

      def initialize(id = nil, name = nil)
        @id = id
        @name = name
      end

      def save!
        true
      end

      def update!(_attrs)
        true
      end

      def destroy
        true
      end
    end

    # Define class methods
    klass.define_singleton_method(:all) do
      [klass.new(1, 'Alice'), klass.new(2, 'Bob')]
    end

    klass.define_singleton_method(:find) do |id|
      klass.new(id.to_i, "User #{id}")
    end

    klass
  end

  let(:controller_class) do
    res_class = resource_class

    Class.new do
      include BetterController::Controllers::ActionHelpers

      attr_accessor :params, :rendered

      def initialize
        @params = {}
        @rendered = nil
      end

      def execute_action
        yield
      end

      def with_transaction
        yield
      end

      def respond_with_success(data, status: :ok)
        @rendered = { success: true, data: data, status: status }
      end

      def respond_with_pagination(collection, options = {})
        @rendered = { success: true, data: collection, pagination: options }
      end

      def user_params
        @params[:user] || {}
      end

      standard_actions res_class
    end
  end

  let(:controller) { controller_class.new }

  describe '.standard_actions' do
    it 'defines index action' do
      expect(controller).to respond_to(:index)
    end

    it 'defines show action' do
      expect(controller).to respond_to(:show)
    end

    it 'defines create action' do
      expect(controller).to respond_to(:create)
    end

    it 'defines update action' do
      expect(controller).to respond_to(:update)
    end

    it 'defines destroy action' do
      expect(controller).to respond_to(:destroy)
    end
  end

  describe '#index' do
    it 'returns all records' do
      controller.index

      expect(controller.rendered[:success]).to be true
      expect(controller.rendered[:data]).to be_an(Array)
    end

    context 'with pagination option' do
      let(:controller_class_paginated) do
        res_class = resource_class

        Class.new do
          include BetterController::Controllers::ActionHelpers

          attr_accessor :params, :rendered

          def initialize
            @params = { page: 1, per_page: 10 }
            @rendered = nil
          end

          def execute_action
            yield
          end

          def respond_with_pagination(collection, options = {})
            @rendered = { success: true, data: collection, pagination: options }
          end

          standard_actions res_class, paginate: true
        end
      end

      it 'calls respond_with_pagination' do
        paginated_controller = controller_class_paginated.new
        paginated_controller.index

        expect(paginated_controller.rendered[:pagination]).to include(:page, :per_page)
      end
    end

    context 'with scopes' do
      let(:controller_with_scopes) do
        res_class = resource_class

        Class.new do
          include BetterController::Controllers::ActionHelpers

          attr_accessor :params, :rendered, :scopes_applied

          def initialize
            @params = {}
            @rendered = nil
            @scopes_applied = false
          end

          def execute_action
            yield
          end

          def apply_scopes(collection)
            @scopes_applied = true
            collection
          end

          def respond_with_success(data, status: :ok)
            @rendered = { success: true, data: data, status: status }
          end

          standard_actions res_class
        end
      end

      it 'applies scopes when available' do
        scoped_controller = controller_with_scopes.new
        scoped_controller.index

        expect(scoped_controller.scopes_applied).to be true
      end
    end
  end

  describe '#show' do
    it 'finds and returns the resource' do
      controller.params = { id: '1' }
      controller.show

      expect(controller.rendered[:success]).to be true
    end
  end

  describe '#create' do
    it 'creates a new resource' do
      controller.params = { user: { name: 'New User' } }
      controller.create

      expect(controller.rendered[:success]).to be true
      expect(controller.rendered[:status]).to eq(:created)
    end
  end

  describe '#update' do
    it 'updates the resource' do
      controller.params = { id: '1', user: { name: 'Updated' } }
      controller.update

      expect(controller.rendered[:success]).to be true
    end
  end

  describe '#destroy' do
    it 'destroys the resource' do
      controller.params = { id: '1' }
      controller.destroy

      expect(controller.rendered[:success]).to be true
      expect(controller.rendered[:status]).to eq(:no_content)
    end
  end
end
