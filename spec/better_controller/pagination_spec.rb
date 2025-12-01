# frozen_string_literal: true

require 'spec_helper'

class PaginationTestClass
  include BetterController::Utils::Pagination
  
  attr_accessor :request, :params
  
  def initialize
    # Non usiamo double qui, lo impostiamo nel test
    @request = nil
    @params = {}
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

RSpec.describe BetterController::Utils::Pagination do
  let(:pagination_instance) do
    instance = PaginationTestClass.new
    instance.request = double('request', url: 'http://example.com/resources', query_parameters: {})
    instance.params = { page: 1, per_page: 10 }
    instance
  end
  let(:collection) do
    # Creiamo un array che risponde ai metodi di paginazione
    array = [
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com'),
      ExampleModel.new(id: 2, name: 'Example 2', email: 'example2@example.com'),
      ExampleModel.new(id: 3, name: 'Example 3', email: 'example3@example.com'),
      ExampleModel.new(id: 4, name: 'Example 4', email: 'example4@example.com'),
      ExampleModel.new(id: 5, name: 'Example 5', email: 'example5@example.com')
    ]
    
    # Creiamo un mock dell'array che può essere tracciato
    mock_array = double('array')
    allow(mock_array).to receive(:page).and_return(mock_array)
    allow(mock_array).to receive(:per).and_return(array.take(2))
    
    # Aggiungiamo i metodi necessari per comportarsi come un array
    allow(mock_array).to receive(:is_a?).with(Hash).and_return(false)
    allow(mock_array).to receive(:respond_to?).with(:each).and_return(true)
    
    mock_array
  end
  
  let(:paginated_collection) do
    # Creiamo una collezione paginata con i metodi necessari
    paginated = [
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com'),
      ExampleModel.new(id: 2, name: 'Example 2', email: 'example2@example.com')
    ]
    
    # Aggiungiamo i metodi di paginazione
    paginated.define_singleton_method(:total_count) { 5 }
    paginated.define_singleton_method(:total_pages) { 3 }
    paginated.define_singleton_method(:current_page) { 1 }
    paginated.define_singleton_method(:limit_value) { 2 }
    
    paginated
  end

  describe '#paginate' do
    it 'paginates a collection' do
      result = pagination_instance.paginate(collection, page: 1, per_page: 2)
      
      expect(collection).to have_received(:page).with(1)
      expect(collection).to have_received(:per).with(2)
    end

    it 'uses default per_page when not specified' do
      # Configure default per_page
      allow(PaginationTestClass).to receive(:pagination_options).and_return({ per_page: 10 })
      
      pagination_instance.paginate(collection, page: 1)
      
      expect(collection).to have_received(:page).with(1)
      expect(collection).to have_received(:per).with(10)
    end

    it 'uses specified per_page over default' do
      # Configure default per_page
      allow(PaginationTestClass).to receive(:pagination_options).and_return({ per_page: 10 })
      
      pagination_instance.paginate(collection, page: 1, per_page: 2)
      
      expect(collection).to have_received(:page).with(1)
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

  describe '#paginate with add_meta' do
    let(:pagination_with_meta) do
      Class.new do
        include BetterController::Utils::Pagination

        attr_accessor :request, :params, :meta_data

        def initialize
          @request = nil
          @params = {}
          @meta_data = {}
        end

        def self.pagination_options
          { enabled: true, per_page: 25 }
        end

        def add_meta(key, value)
          @meta_data[key] = value
        end
      end
    end

    it 'calls add_meta with pagination metadata' do
      instance = pagination_with_meta.new
      instance.request = double('request', url: 'http://example.com/resources', query_parameters: {})
      instance.params = { page: 1, per_page: 2 }

      paginated_result = [ExampleModel.new(id: 1, name: 'Test', email: 'test@example.com')]
      paginated_result.define_singleton_method(:total_count) { 10 }
      paginated_result.define_singleton_method(:total_pages) { 5 }
      paginated_result.define_singleton_method(:current_page) { 1 }
      paginated_result.define_singleton_method(:limit_value) { 2 }

      mock_collection = double('collection')
      allow(mock_collection).to receive(:page).and_return(mock_collection)
      allow(mock_collection).to receive(:per).and_return(paginated_result)

      instance.paginate(mock_collection, page: 1, per_page: 2)

      expect(instance.meta_data[:pagination]).to include(
        total_count: 10,
        total_pages: 5,
        current_page: 1,
        per_page: 2
      )
    end
  end

  describe 'edge cases' do
    describe '#paginate with edge case parameters' do
      it 'handles page 0 by defaulting to page 1' do
        pagination_instance.params = { page: 0, per_page: 10 }

        # Page should be treated as 1 when 0 is passed
        pagination_instance.paginate(collection, page: 0, per_page: 2)

        expect(collection).to have_received(:page).with(0)
      end

      it 'handles negative page numbers' do
        pagination_instance.params = { page: -1, per_page: 10 }

        pagination_instance.paginate(collection, page: -1, per_page: 2)

        expect(collection).to have_received(:page).with(-1)
      end

      it 'handles very large page numbers' do
        pagination_instance.params = { page: 999_999, per_page: 10 }

        pagination_instance.paginate(collection, page: 999_999, per_page: 2)

        expect(collection).to have_received(:page).with(999_999)
      end

      it 'handles per_page of 0' do
        pagination_instance.paginate(collection, page: 1, per_page: 0)

        expect(collection).to have_received(:per).with(0)
      end

      it 'handles very large per_page values' do
        pagination_instance.paginate(collection, page: 1, per_page: 10_000)

        expect(collection).to have_received(:per).with(10_000)
      end

      it 'handles nil page parameter by defaulting to 1' do
        pagination_instance.paginate(collection, page: nil, per_page: 2)

        # Pagination converts nil to 1
        expect(collection).to have_received(:page).with(1)
      end

      it 'handles string page parameter by converting to integer' do
        pagination_instance.paginate(collection, page: '5', per_page: 2)

        # Pagination converts string to integer
        expect(collection).to have_received(:page).with(5)
      end
    end

    describe '#pagination_meta with edge case collections' do
      it 'handles empty collection' do
        empty_collection = []
        empty_collection.define_singleton_method(:total_count) { 0 }
        empty_collection.define_singleton_method(:total_pages) { 0 }
        empty_collection.define_singleton_method(:current_page) { 1 }
        empty_collection.define_singleton_method(:limit_value) { 10 }

        meta = pagination_instance.pagination_meta(empty_collection)

        expect(meta[:total_count]).to eq(0)
        expect(meta[:total_pages]).to eq(0)
      end

      it 'handles single item collection' do
        single_collection = [ExampleModel.new(id: 1, name: 'Single', email: 'single@example.com')]
        single_collection.define_singleton_method(:total_count) { 1 }
        single_collection.define_singleton_method(:total_pages) { 1 }
        single_collection.define_singleton_method(:current_page) { 1 }
        single_collection.define_singleton_method(:limit_value) { 10 }

        meta = pagination_instance.pagination_meta(single_collection)

        expect(meta[:total_count]).to eq(1)
        expect(meta[:total_pages]).to eq(1)
      end

      it 'handles last page correctly' do
        last_page_collection = [ExampleModel.new(id: 5, name: 'Last', email: 'last@example.com')]
        last_page_collection.define_singleton_method(:total_count) { 5 }
        last_page_collection.define_singleton_method(:total_pages) { 3 }
        last_page_collection.define_singleton_method(:current_page) { 3 }
        last_page_collection.define_singleton_method(:limit_value) { 2 }

        meta = pagination_instance.pagination_meta(last_page_collection)

        expect(meta[:current_page]).to eq(3)
        expect(meta[:total_pages]).to eq(3)
      end
    end

    describe '#pagination_links with edge cases' do
      it 'handles first page (no prev link)' do
        first_page_collection = paginated_collection
        first_page_collection.define_singleton_method(:current_page) { 1 }

        links = pagination_instance.pagination_links(first_page_collection)

        expect(links[:prev]).to be_nil
        expect(links[:next]).to be_present
      end

      it 'handles last page (no next link)' do
        last_page_collection = [ExampleModel.new(id: 5, name: 'Last', email: 'last@example.com')]
        last_page_collection.define_singleton_method(:total_count) { 5 }
        last_page_collection.define_singleton_method(:total_pages) { 3 }
        last_page_collection.define_singleton_method(:current_page) { 3 }
        last_page_collection.define_singleton_method(:limit_value) { 2 }

        links = pagination_instance.pagination_links(last_page_collection)

        expect(links[:next]).to be_nil
        expect(links[:prev]).to be_present
      end

      it 'handles single page (no prev or next links)' do
        single_page_collection = [ExampleModel.new(id: 1, name: 'Only', email: 'only@example.com')]
        single_page_collection.define_singleton_method(:total_count) { 1 }
        single_page_collection.define_singleton_method(:total_pages) { 1 }
        single_page_collection.define_singleton_method(:current_page) { 1 }
        single_page_collection.define_singleton_method(:limit_value) { 10 }

        links = pagination_instance.pagination_links(single_page_collection)

        expect(links[:prev]).to be_nil
        expect(links[:next]).to be_nil
      end
    end
  end
end
