# frozen_string_literal: true

module BetterController
  module Generators
    # Generator for installing BetterController
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def create_initializer
        template 'initializer.rb', 'config/initializers/better_controller.rb'
      end

      def mount_routes
        route '# BetterController routes can be added here'
      end

      def show_readme
        readme 'README' if behavior == :invoke
      end
    end
  end
end
