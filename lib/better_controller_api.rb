# frozen_string_literal: true

require 'better_controller'

# BetterControllerApi - Shortcut module for API controllers
# This is a shortcut for including API-specific modules without Turbo/ViewComponent support
#
# @example
#   class Api::UsersController < ApplicationController
#     include BetterControllerApi
#
#     def index
#       users = User.all
#       respond_with_success(users)
#     end
#
#     def show
#       user = User.find(params[:id])
#       respond_with_success(user)
#     rescue ActiveRecord::RecordNotFound => e
#       respond_with_error(e, status: :not_found)
#     end
#   end
module BetterControllerApi
  # Include API-specific modules in a controller
  # @param base [Class] The controller class
  def self.included(base)
    base.include(BetterController::Controllers::Base)
    base.include(BetterController::Controllers::ResponseHelpers)
    base.include(BetterController::Utils::ParameterValidation)
    base.include(BetterController::Utils::ParamsHelpers)
    base.include(BetterController::Utils::Logging)
    base.include(BetterController::Utils::Pagination)
    base.extend(BetterController::Controllers::ActionHelpers::ClassMethods)
    base.extend(BetterController::Utils::Logging::ClassMethods)
  end
end
