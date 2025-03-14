# frozen_string_literal: true

module BetterController
  # Module providing helper methods for common controller actions
  module ActionHelpers
    extend ActiveSupport::Concern

    # Define standard CRUD actions for a resource
    # @param resource_class [Class] The resource class (e.g., User)
    # @param options [Hash] Options for customizing the actions
    module ClassMethods
      def standard_actions(resource_class, options = {})
        resource_name   = resource_class.name.underscore
        resource_name.pluralize

        # Define index action
        define_method(:index) do
          execute_action do
            collection = resource_class.all

            # Apply scopes if provided
            collection = apply_scopes(collection) if respond_to?(:apply_scopes)

            # Apply pagination if requested
            if options[:paginate]
              respond_with_pagination(collection, page: params[:page], per_page: params[:per_page])
            else
              respond_with_success(collection)
            end
          end
        end

        # Define show action
        define_method(:show) do
          execute_action do
            resource = resource_class.find(params[:id])
            respond_with_success(resource)
          end
        end

        # Define create action
        define_method(:create) do
          execute_action do
            resource = resource_class.new(send(:"#{resource_name}_params"))

            with_transaction do
              resource.save!
              respond_with_success(resource, status: :created)
            end
          end
        end

        # Define update action
        define_method(:update) do
          execute_action do
            resource = resource_class.find(params[:id])

            with_transaction do
              resource.update!(send(:"#{resource_name}_params"))
              respond_with_success(resource)
            end
          end
        end

        # Define destroy action
        define_method(:destroy) do
          execute_action do
            resource = resource_class.find(params[:id])
            resource.destroy
            respond_with_success(nil, status: :no_content)
          end
        end
      end
    end
  end
end
