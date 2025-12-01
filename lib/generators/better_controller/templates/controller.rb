# frozen_string_literal: true

class <%= class_name %>Controller < ApplicationController
  include BetterController::Controllers::ResourcesController

<% if has_action?(:index) -%>
  # GET /<%= file_name %>
  # def index
  #   # Default implementation from ResourcesController
  #   # Override to customize
  # end

<% end -%>
<% if has_action?(:show) -%>
  # GET /<%= file_name %>/:id
  # def show
  #   # Default implementation from ResourcesController
  #   # Override to customize
  # end

<% end -%>
<% if has_action?(:new) -%>
  # GET /<%= file_name %>/new
  # def new
  #   # Override to customize
  # end

<% end -%>
<% if has_action?(:create) -%>
  # POST /<%= file_name %>
  # def create
  #   # Default implementation from ResourcesController
  #   # Override to customize
  # end

<% end -%>
<% if has_action?(:edit) -%>
  # GET /<%= file_name %>/:id/edit
  # def edit
  #   # Override to customize
  # end

<% end -%>
<% if has_action?(:update) -%>
  # PATCH/PUT /<%= file_name %>/:id
  # def update
  #   # Default implementation from ResourcesController
  #   # Override to customize
  # end

<% end -%>
<% if has_action?(:destroy) -%>
  # DELETE /<%= file_name %>/:id
  # def destroy
  #   # Default implementation from ResourcesController
  #   # Override to customize
  # end

<% end -%>
  private

  # Define the resource class
  def resource_class
    <%= model_class_name %>
  end

  # Define the permitted parameters
  def resource_params
    params.require(:<%= model_name.underscore %>).permit(
      # Add your permitted attributes here
    )
  end

  # Override to customize serialization (optional)
  # def serialize_resource(resource)
  #   resource.as_json
  # end
end
