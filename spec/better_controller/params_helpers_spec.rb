# frozen_string_literal: true

require 'spec_helper'
require 'date'
require 'time'
require 'json'

class ParamsHelpersTestClass
  include BetterController::Utils::ParamsHelpers
  
  attr_accessor :params
  
  def initialize(params = {})
    @params = params
  end

  # Mock method to make ActionController::ParameterMissing work
  def require_params(key)
    if params.key?(key)
      params[key]
    else
      raise ActionController::ParameterMissing.new(key)
    end
  end
end

RSpec.describe BetterController::Utils::ParamsHelpers do
  let(:params) do
    {
      id: '1',
      name: 'Test',
      active: 'true',
      count: '10',
      date: '2025-03-14',
      datetime: '2025-03-14T10:00:00',
      json_data: '{"key":"value"}',
      array: ['1', '2', '3'],
      nested: { key: 'value' }
    }
  end
  let(:helpers) { ParamsHelpersTestClass.new(params) }

  describe '#param' do
    it 'returns the parameter value' do
      expect(helpers.param(:id)).to eq('1')
    end
    
    it 'returns the default value if parameter is missing' do
      expect(helpers.param(:missing, default: 'default')).to eq('default')
    end
    
    it 'converts the parameter to the specified type' do
      expect(helpers.param(:id, type: :integer)).to eq(1)
      expect(helpers.param(:count, type: :integer)).to eq(10)
    end
    
    it 'raises an error if required parameter is missing' do
      # Mock the require_params method to raise ActionController::ParameterMissing
      expect { helpers.param(:missing, required: true) }.to raise_error(ActionController::ParameterMissing)
    end
  end
  
  describe '#boolean_param' do
    it 'converts string to boolean' do
      expect(helpers.boolean_param(:active)).to eq(true)
    end
    
    it 'returns the default value if parameter is missing' do
      expect(helpers.boolean_param(:missing, default: false)).to eq(false)
    end
  end
  
  describe '#integer_param' do
    it 'converts string to integer' do
      expect(helpers.integer_param(:count)).to eq(10)
    end
    
    it 'returns the default value if parameter is missing' do
      expect(helpers.integer_param(:missing, default: 0)).to eq(0)
    end
  end
  
  describe '#date_param' do
    it 'converts string to date' do
      # Mock Date.parse to return a specific date
      allow(Date).to receive(:parse).with('2025-03-14').and_return(Date.new(2025, 3, 14))
      
      expect(helpers.date_param(:date)).to be_a(Date)
      expect(helpers.date_param(:date).to_s).to eq('2025-03-14')
    end
    
    it 'returns the default value if parameter is missing' do
      default_date = Date.new(2025, 1, 1)
      expect(helpers.date_param(:missing, default: default_date)).to eq(default_date)
    end
  end
  
  describe '#datetime_param' do
    it 'converts string to datetime' do
      # Mock Time.parse to return a specific time
      allow(Time).to receive(:parse).with('2025-03-14T10:00:00').and_return(Time.new(2025, 3, 14, 10, 0, 0))
      
      result = helpers.datetime_param(:datetime)
      expect(result).to be_a(Time)
      expect(result.year).to eq(2025)
      expect(result.month).to eq(3)
      expect(result.day).to eq(14)
      expect(result.hour).to eq(10)
    end
    
    it 'returns the default value if parameter is missing' do
      default_datetime = Time.new(2025, 1, 1, 0, 0, 0)
      expect(helpers.datetime_param(:missing, default: default_datetime)).to eq(default_datetime)
    end
  end
  
  describe '#json_param' do
    it 'parses JSON string' do
      # Mock JSON.parse to return a specific hash
      allow(JSON).to receive(:parse).with('{"key":"value"}').and_return({ 'key' => 'value' })
      
      expect(helpers.json_param(:json_data)).to eq({ 'key' => 'value' })
    end
    
    it 'returns the default value if parameter is missing' do
      expect(helpers.json_param(:missing, default: {})).to eq({})
    end
  end
  
  describe '#array_param' do
    it 'returns array parameter' do
      expect(helpers.array_param(:array)).to eq(['1', '2', '3'])
    end
    
    it 'returns the default value if parameter is missing' do
      expect(helpers.array_param(:missing, default: [])).to eq([])
    end
  end
  
  describe '#hash_param' do
    it 'returns hash parameter' do
      expect(helpers.hash_param(:nested)).to eq({ key: 'value' })
    end

    it 'returns the default value if parameter is missing' do
      expect(helpers.hash_param(:missing, default: {})).to eq({})
    end
  end

  describe '#float_param' do
    let(:float_params) { { price: '19.99' } }
    let(:float_helpers) { ParamsHelpersTestClass.new(float_params) }

    it 'converts string to float' do
      expect(float_helpers.float_param(:price)).to eq(19.99)
    end

    it 'returns the default value if parameter is missing' do
      expect(float_helpers.float_param(:missing, default: 0.0)).to eq(0.0)
    end
  end

  describe '#param with type :float' do
    let(:float_params) { { value: '3.14' } }
    let(:float_helpers) { ParamsHelpersTestClass.new(float_params) }

    it 'converts to float with :float symbol type' do
      expect(float_helpers.param(:value, type: :float)).to eq(3.14)
    end
  end

  describe '#param with type :string' do
    let(:string_params) { { id: 123 } }
    let(:string_helpers) { ParamsHelpersTestClass.new(string_params) }

    it 'converts to string with :string symbol type' do
      expect(string_helpers.param(:id, type: :string)).to eq('123')
    end
  end

  describe '#param date parsing edge cases' do
    let(:date_params) { { invalid_date: 'not-a-date' } }
    let(:date_helpers) { ParamsHelpersTestClass.new(date_params) }

    it 'returns default on invalid date' do
      default_date = Date.new(2020, 1, 1)
      result = date_helpers.param(:invalid_date, type: :date, default: default_date)

      expect(result).to eq(default_date)
    end
  end

  describe '#param datetime parsing edge cases' do
    let(:datetime_params) { { invalid_datetime: 'not-a-datetime' } }
    let(:datetime_helpers) { ParamsHelpersTestClass.new(datetime_params) }

    it 'returns default on invalid datetime' do
      default_time = Time.new(2020, 1, 1)
      result = datetime_helpers.param(:invalid_datetime, type: :datetime, default: default_time)

      expect(result).to eq(default_time)
    end

  end

  describe '#param JSON parsing edge cases' do
    let(:json_params) { { invalid_json: 'not-valid-json' } }
    let(:json_helpers) { ParamsHelpersTestClass.new(json_params) }

    it 'returns default on invalid JSON' do
      default_hash = { fallback: true }
      result = json_helpers.param(:invalid_json, type: :json, default: default_hash)

      expect(result).to eq(default_hash)
    end
  end

  describe '#datetime_param edge cases' do
    context 'when value is already a Time object' do
      let(:time_value) { Time.new(2025, 6, 15, 12, 30, 0) }
      let(:time_params) { { timestamp: time_value } }
      let(:time_helpers) { ParamsHelpersTestClass.new(time_params) }

      it 'returns the Time object as-is' do
        result = time_helpers.datetime_param(:timestamp)

        expect(result).to eq(time_value)
      end
    end

    context 'when value cannot be parsed' do
      let(:invalid_params) { { bad_time: 'not-a-valid-time' } }
      let(:invalid_helpers) { ParamsHelpersTestClass.new(invalid_params) }

      it 'returns default on ArgumentError' do
        default_time = Time.new(2020, 1, 1)
        result = invalid_helpers.datetime_param(:bad_time, default: default_time)

        expect(result).to eq(default_time)
      end
    end
  end

  describe '#param with array type' do
    context 'when value is not an array' do
      let(:single_params) { { items: 'single' } }
      let(:single_helpers) { ParamsHelpersTestClass.new(single_params) }

      it 'wraps single value in array' do
        result = single_helpers.param(:items, type: :array)

        expect(result).to eq(['single'])
      end
    end
  end

  describe '#param with hash type' do
    context 'when value is not a hash' do
      let(:non_hash_params) { { data: 'string' } }
      let(:non_hash_helpers) { ParamsHelpersTestClass.new(non_hash_params) }

      it 'returns default when value is not a hash' do
        default_hash = { default: true }
        result = non_hash_helpers.param(:data, type: :hash, default: default_hash)

        expect(result).to eq(default_hash)
      end
    end
  end

  describe '#param with json type when value is already a hash' do
    let(:hash_params) { { data: { already: 'hash' } } }
    let(:hash_helpers) { ParamsHelpersTestClass.new(hash_params) }

    it 'returns hash as-is without parsing' do
      result = hash_helpers.param(:data, type: :json)

      expect(result).to eq({ already: 'hash' })
    end
  end
end
