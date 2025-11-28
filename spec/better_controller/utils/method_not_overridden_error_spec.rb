# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BetterController::Utils::MethodNotOverriddenError do
  describe '#initialize' do
    let(:test_class) do
      Class.new do
        def self.name
          'TestClass'
        end
      end
    end

    let(:instance) { test_class.new }

    it 'creates an error with method name and class' do
      error = described_class.new(:my_method, instance)

      expect(error.message).to include('my_method')
      expect(error.message).to include('TestClass')
    end

    it 'accepts string method name' do
      error = described_class.new('other_method', instance)

      expect(error.message).to include('other_method')
    end

    it 'formats message correctly' do
      error = described_class.new(:execute, instance)

      expect(error.message).to eq("Method 'execute' must be overridden in TestClass")
    end

    it 'is a StandardError subclass' do
      error = described_class.new(:method, instance)

      expect(error).to be_a(StandardError)
    end

    it 'can be raised and caught' do
      expect do
        raise described_class.new(:call, instance)
      end.to raise_error(BetterController::Utils::MethodNotOverriddenError)
    end

    it 'works with anonymous classes' do
      anonymous_instance = Class.new.new
      error = described_class.new(:test, anonymous_instance)

      expect(error.message).to include('must be overridden')
    end
  end
end
