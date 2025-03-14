# frozen_string_literal: true

class <%= class_name %>Controller < ApplicationController
  include BetterController::ResourcesController
  
<% if has_action?(:index) -%>
  # GET /<%= file_name %>
  def index
    execute_action do
      @resource_collection = resource_collection_resolver
      data = serialize_resource(@resource_collection, index_serializer)
      respond_with_success(data, options: { meta: meta })
    end
  end
<% end -%>

<% if has_action?(:show) -%>
  # GET /<%= file_name %>/:id
  def show
    execute_action do
      @resource = resource_resolver
      data = serialize_resource(@resource, show_serializer)
      respond_with_success(data)
    end
  end
<% end -%>

<% if has_action?(:create) -%>
  # POST /<%= file_name %>
  def create
    execute_action do
      @resource = resource_service.create(resource_params)
      data = serialize_resource(@resource, create_serializer)
      respond_with_success(data, status: :created)
    end
  end
<% end -%>

<% if has_action?(:update) -%>
  # PATCH/PUT /<%= file_name %>/:id
  def update
    execute_action do
      @resource = resource_resolver
      resource_service.update(@resource, resource_params)
      data = serialize_resource(@resource, update_serializer)
      respond_with_success(data)
    end
  end
<% end -%>

<% if has_action?(:destroy) -%>
  # DELETE /<%= file_name %>/:id
  def destroy
    execute_action do
      @resource = resource_resolver
      resource_service.destroy(@resource)
      respond_with_success(nil, status: :no_content)
    end
  end
<% end -%>

  protected

  # Define the resource service class
  def resource_service_class
    <%= service_class_name %>
  end

  # Define the root key for resource parameters
  def resource_params_root_key
    :<%= model_name.underscore %>
  end

  # Define the resource serializer class
  def resource_serializer
    <%= serializer_class_name %>
  end
end
