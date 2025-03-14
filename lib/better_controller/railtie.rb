# frozen_string_literal: true

module BetterController
  # Railtie for Rails integration
  class Railtie < Rails::Railtie
    initializer 'better_controller.configure_rails_initialization' do
      ActiveSupport.on_load(:action_controller) do
        # Make BetterController modules available to ActionController
        ActiveSupport.on_load(:action_controller) { include BetterController }
      end
    end

    # Add custom rake tasks if needed
    rake_tasks do
      load 'tasks/better_controller_tasks.rake'
    end
  end
end
