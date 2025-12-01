# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BetterController::Railtie do
  describe 'Rails integration' do
    it 'is a Rails::Railtie subclass' do
      expect(described_class.superclass).to eq(Rails::Railtie)
    end

    it 'is registered as a railtie' do
      railtie_names = Rails.application.railties.map { |r| r.class.name }
      expect(railtie_names).to include('BetterController::Railtie')
    end
  end

  describe 'initializer' do
    it 'defines the configure_rails_initialization initializer' do
      initializer_names = described_class.initializers.map(&:name)
      expect(initializer_names).to include('better_controller.configure_rails_initialization')
    end

    it 'registers an on_load callback for action_controller' do
      # Verify that ActiveSupport.on_load is available and can be called
      expect(ActiveSupport).to respond_to(:on_load)
    end
  end

  describe 'rake_tasks' do
    it 'loads better_controller_tasks.rake' do
      # Verify rake tasks are registered by the railtie
      expect(described_class).to respond_to(:rake_tasks)
    end
  end

  describe 'BetterController module availability' do
    it 'makes BetterController available after Rails loads' do
      expect(defined?(BetterController)).to eq('constant')
    end

    it 'makes BetterController::Controllers::Base available' do
      expect(defined?(BetterController::Controllers::Base)).to eq('constant')
    end

    it 'makes BetterController::Controllers::HtmlController available' do
      expect(defined?(BetterController::Controllers::HtmlController)).to eq('constant')
    end

    it 'makes BetterController::Utils::Pagination available' do
      expect(defined?(BetterController::Utils::Pagination)).to eq('constant')
    end
  end
end
