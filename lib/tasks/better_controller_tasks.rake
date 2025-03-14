# frozen_string_literal: true

namespace :better_controller do
  desc 'Print the BetterController version'
  task version: :environment do
    require 'better_controller/version'
    puts "BetterController version: #{BetterController::VERSION}"
  end

  desc 'Generate a new controller using BetterController'
  task :generate_controller, %i[name model] => :environment do |_, args|
    name  = args[:name]
    model = args[:model]

    if name.blank?
      puts 'Error: Controller name is required'
      puts 'Usage: rake better_controller:generate_controller[name,model]'
      next
    end

    model_class     = model.presence || name.singularize
    controller_name = "#{name.camelize}Controller"
    file_path       = Rails.root.join('app', 'controllers', "#{name.underscore}_controller.rb")

    template = <<~RUBY
      # frozen_string_literal: true

      class #{controller_name} < ApplicationController
        include BetterController::ResourcesController
      #{'  '}
        # Define required parameters for actions
        requires_params :create, :id  # Add your required params
      #{'  '}
        # Define parameter schema for validation
        param_schema :create, {
          # Add your parameter schema here
        }
      #{'  '}
        protected
      #{'  '}
        # Define the resource service class
        def resource_service_class
          #{model_class.camelize}Service
        end
      #{'  '}
        # Define the root key for resource parameters
        def resource_params_root_key
          :#{model_class.underscore}
        end
      #{'  '}
        # Define the resource serializer class
        def resource_serializer
          #{model_class.camelize}Serializer
        end
      end
    RUBY

    File.write(file_path, template)
    puts "Created controller at #{file_path}"
  end
end
