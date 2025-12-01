# frozen_string_literal: true

module BetterController
  module Generators
    # Generator for creating a controller with BetterController
    #
    # @example Generate a users controller
    #   rails generate better_controller:controller Users
    #
    # @example Generate a controller with specific actions
    #   rails generate better_controller:controller Users index show create
    #
    # @example Generate a controller with a custom model
    #   rails generate better_controller:controller Users --model=Account
    #
    class ControllerGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      argument :actions, type: :array, default: [], banner: 'action action'
      class_option :model, type: :string, desc: 'Specify the model name (defaults to singular of controller name)'

      def create_controller_file
        template 'controller.rb', File.join('app/controllers', class_path, "#{file_name}_controller.rb")
      end

      private

      def model_name
        options[:model] || file_name.singularize
      end

      def model_class_name
        model_name.camelize
      end

      def controller_actions
        actions.map(&:to_sym)
      end

      def has_action?(action)
        controller_actions.include?(action.to_sym) || controller_actions.empty?
      end
    end
  end
end
