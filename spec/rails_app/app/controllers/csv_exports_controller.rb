# frozen_string_literal: true

class CsvExportsController < ApplicationController
  include BetterController::Controllers::ResourcesController
  include BetterController::Controllers::Concerns::CsvSupport

  def index
    execute_action do
      users = resource_scope
      respond_to do |format|
        format.html { render plain: 'Users list' }
        format.json { respond_with_success(serialize_collection(users)) }
        format.csv do
          send_csv users,
                   filename: "users_export_#{Date.current}.csv",
                   columns: %i[id name email created_at],
                   headers: {
                     id: 'User ID',
                     name: 'Full Name',
                     email: 'Email Address',
                     created_at: 'Registration Date'
                   }
        end
      end
    end
  end

  def show
    execute_action do
      user = find_resource
      respond_to do |format|
        format.html { render plain: "User: #{user.name}" }
        format.json { respond_with_success(serialize_resource(user)) }
        format.csv do
          send_csv [user],
                   filename: "user_#{user.id}.csv",
                   columns: %i[id name email created_at],
                   headers: {
                     id: 'User ID',
                     name: 'Full Name',
                     email: 'Email Address',
                     created_at: 'Registration Date'
                   }
        end
      end
    end
  end

  private

  def resource_class
    User
  end

  def resource_params
    params.require(:user).permit(:name, :email)
  end

  def serialize_resource(resource)
    resource.as_json(only: %i[id name email created_at])
  end
end
