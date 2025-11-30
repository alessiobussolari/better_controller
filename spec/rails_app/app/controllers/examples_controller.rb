# frozen_string_literal: true

class ExamplesController < ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Example
  end

  def resource_params
    params.require(:example).permit(:name, :email)
  end
end
