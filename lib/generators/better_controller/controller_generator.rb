# frozen_string_literal: true

module BetterController
  module Generators
    # Generator for creating a controller with BetterController
    class ControllerGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      argument :actions, type: :array, default: [], banner: 'action action'
      class_option :skip_service, type: :boolean, default: false, desc: 'Skip generating a service'
      class_option :skip_serializer, type: :boolean, default: false, desc: 'Skip generating a serializer'
      class_option :model, type: :string, desc: 'Specify the model name (defaults to singular of controller name)'

      def create_controller_file
        template 'controller.rb', File.join('app/controllers', "#{file_name}_controller.rb")
      end

      def create_service_file
        return if options[:skip_service]

        template 'service.rb', File.join('app/services', "#{service_file_name}_service.rb")
      end

      def create_serializer_file
        return if options[:skip_serializer]

        template 'serializer.rb', File.join('app/serializers', "#{serializer_file_name}_serializer.rb")
      end

      private

      def model_name
        options[:model] || file_name.singularize
      end

      def service_file_name
        model_name.underscore
      end

      def serializer_file_name
        model_name.underscore
      end

      def model_class_name
        model_name.camelize
      end

      def service_class_name
        "#{model_class_name}Service"
      end

      def serializer_class_name
        "#{model_class_name}Serializer"
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
