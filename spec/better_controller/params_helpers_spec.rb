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
end
