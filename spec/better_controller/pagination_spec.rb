# frozen_string_literal: true

require 'spec_helper'

class PaginationTestClass
  include BetterController::Pagination
  
  attr_accessor :request
  
  def initialize
    @request = double('request', url: 'http://example.com/resources', query_parameters: {})
  end
  
  # Mock the class method for pagination options
  def self.pagination_options
    { enabled: true, per_page: 25 }
  end
  
  # Mock the configure_pagination class method
  def self.configure_pagination(options = {})
    @pagination_options = options
  end
end

# Mock the BetterController configuration
module BetterController
  def self.configuration
    @configuration ||= { pagination: { per_page: 25 } }
  end
end

RSpec.describe BetterController::Pagination do
  let(:pagination_instance) { PaginationTestClass.new }
  let(:collection) do
    [
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com'),
      ExampleModel.new(id: 2, name: 'Example 2', email: 'example2@example.com'),
      ExampleModel.new(id: 3, name: 'Example 3', email: 'example3@example.com'),
      ExampleModel.new(id: 4, name: 'Example 4', email: 'example4@example.com'),
      ExampleModel.new(id: 5, name: 'Example 5', email: 'example5@example.com')
    ]
  end
  
  let(:paginated_collection) { collection.take(2) }

  before do
    # Mock the collection to respond to pagination methods
    allow(collection).to receive(:page).and_return(collection)
    allow(collection).to receive(:per).and_return(paginated_collection)
    
    # Mock pagination metadata methods
    allow(paginated_collection).to receive(:total_count).and_return(5)
    allow(paginated_collection).to receive(:total_pages).and_return(3)
    allow(paginated_collection).to receive(:current_page).and_return(1)
    allow(paginated_collection).to receive(:limit_value).and_return(2)
  end

  describe '#paginate' do
    it 'paginates a collection' do
      result = pagination_instance.paginate(collection, page: 1, per_page: 2)
      
      expect(result).to eq(paginated_collection)
    end

    it 'uses default per_page when not specified' do
      # Configure default per_page
      allow(PaginationTestClass).to receive(:pagination_options).and_return({ per_page: 10 })
      
      pagination_instance.paginate(collection, page: 1)
      
      expect(collection).to have_received(:per).with(10)
    end

    it 'uses specified per_page over default' do
      # Configure default per_page
      allow(PaginationTestClass).to receive(:pagination_options).and_return({ per_page: 10 })
      
      pagination_instance.paginate(collection, page: 1, per_page: 2)
      
      expect(collection).to have_received(:per).with(2)
    end
  end

  describe '#pagination_meta' do
    it 'returns pagination metadata' do
      meta = pagination_instance.pagination_meta(paginated_collection)
      
      expect(meta).to include(
        total_count: 5,
        total_pages: 3,
        current_page: 1,
        per_page: 2
      )
    end
  end

  describe '#pagination_links' do
    it 'returns pagination links' do
      links = pagination_instance.pagination_links(paginated_collection)
      
      expect(links).to include(:self, :first, :last, :next)
      expect(links[:self]).to include('http://example.com/resources')
      expect(links[:next]).to include('page=2')
    end
  end
end
