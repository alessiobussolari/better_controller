# frozen_string_literal: true

module BetterController
  module Utils
    # Module providing enhanced parameter handling for controllers
    module ParamsHelpers
      extend ActiveSupport::Concern

      # Get parameters with type casting
      # @param key [Symbol, String] The parameter key
      # @param type [Class] The type to cast to
      # @param default [Object] The default value if parameter is missing
      # @return [Object] The parameter value
      def param(key, type: nil, default: nil, required: false)
        value = params[key]
        if required && value.nil?
          raise ActionController::ParameterMissing.new(key)
        end
        return default if value.nil?

        case type
        when :integer, Integer
          value.to_i
        when :float, Float
          value.to_f
        when :string, String
          value.to_s
        when :boolean, :bool
          ActiveModel::Type::Boolean.new.cast(value)
        when :date, Date
          begin
            Date.parse(value)
          rescue ArgumentError
            default
          end
        when :datetime, DateTime, Time
          begin
            Time.parse(value.to_s)
          rescue ArgumentError
            default
          end
        when :array, Array
          value.is_a?(Array) ? value : [value]
        when :hash, Hash
          value.is_a?(Hash) ? value : default
        when :json, :JSON
          begin
            value.is_a?(Hash) ? value : JSON.parse(value)
          rescue JSON::ParserError
            default
          end
        else
          value
        end
      end

      # Get a boolean parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Boolean] The default value if parameter is missing
      # @return [Boolean] The parameter value
      def boolean_param(key, default: false)
        param(key, type: :boolean, default: default)
      end

      # Get an integer parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Integer] The default value if parameter is missing
      # @return [Integer] The parameter value
      def integer_param(key, default: nil)
        param(key, type: :integer, default: default)
      end

      # Get a float parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Float] The default value if parameter is missing
      # @return [Float] The parameter value
      def float_param(key, default: nil)
        param(key, type: :float, default: default)
      end

      # Get a date parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Date] The default value if parameter is missing
      # @return [Date] The parameter value
      def date_param(key, default: nil)
        param(key, type: :date, default: default)
      end

      # Get a datetime parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Time] The default value if parameter is missing
      # @return [Time] The parameter value
      def datetime_param(key, default: nil)
        value = param(key, default: default)
        return default if value.nil?
        
        begin
          value.is_a?(Time) ? value : Time.parse(value.to_s)
        rescue ArgumentError
          default
        end
      end

      # Get an array parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Array] The default value if parameter is missing
      # @return [Array] The parameter value
      def array_param(key, default: [])
        param(key, type: :array, default: default)
      end

      # Get a JSON parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Hash] The default value if parameter is missing
      # @return [Hash] The parameter value
      def json_param(key, default: {})
        param(key, type: :json, default: default)
      end

      # Get a hash parameter
      # @param key [Symbol, String] The parameter key
      # @param default [Hash] The default value if parameter is missing
      # @return [Hash] The parameter value
      def hash_param(key, default: {})
        param(key, type: :hash, default: default)
      end
    end
  end
end
