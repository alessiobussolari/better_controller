# frozen_string_literal: true

module Api
  class UsersController < ActionController::API
    include BetterControllerApi

    def index
      users = User.all
      respond_with_success(users)
    end

    def show
      user = User.find(params[:id])
      respond_with_success(user)
    rescue ActiveRecord::RecordNotFound => e
      respond_with_error(e, status: :not_found)
    end

    def create
      user = User.create!(user_params)
      respond_with_success(user, status: :created)
    rescue ActiveRecord::RecordInvalid => e
      respond_with_error(e, status: :unprocessable_entity)
    end

    def update
      user = User.find(params[:id])
      user.update!(user_params)
      respond_with_success(user)
    rescue ActiveRecord::RecordNotFound => e
      respond_with_error(e, status: :not_found)
    rescue ActiveRecord::RecordInvalid => e
      respond_with_error(e, status: :unprocessable_entity)
    end

    def destroy
      user = User.find(params[:id])
      user.destroy!
      respond_with_success({ deleted: true })
    rescue ActiveRecord::RecordNotFound => e
      respond_with_error(e, status: :not_found)
    end

    private

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
