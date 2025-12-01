# frozen_string_literal: true

# TasksController demonstrates a custom controller with multi-format responses
# Uses format checking for HTML and JSON formats
class TasksController < ApplicationController
  include BetterController::Controllers::Base
  include BetterController::Controllers::ResponseHelpers

  def index
    @tasks = Task.all
    if request.format.json?
      render json: { data: @tasks, meta: { version: 'v1' } }
    else
      render json: { tasks: @tasks }
    end
  end

  def show
    @task = Task.find(params[:id])
    if request.format.json?
      render json: { data: @task, meta: { version: 'v1' } }
    else
      render json: { task: @task }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Task not found' }, status: :not_found
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      if request.format.json?
        render json: { data: @task, meta: { version: 'v1' } }, status: :created
      else
        render json: { task: @task }, status: :created
      end
    else
      render json: { errors: @task.errors }, status: :unprocessable_entity
    end
  end

  def update
    @task = Task.find(params[:id])
    if @task.update(task_params)
      if request.format.json?
        render json: { data: @task, meta: { version: 'v1' } }
      else
        render json: { task: @task }
      end
    else
      render json: { errors: @task.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Task not found' }, status: :not_found
  end

  def destroy
    @task = Task.find(params[:id])
    @task.destroy
    if request.format.json?
      render json: { data: { deleted: true }, meta: { version: 'v1' } }
    else
      render json: { deleted: true }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Task not found' }, status: :not_found
  end

  def complete
    @task = Task.find(params[:id])
    @task.complete!
    if request.format.json?
      render json: { data: @task, meta: { version: 'v1' } }
    else
      render json: { task: @task }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Task not found' }, status: :not_found
  end

  private

  def task_params
    return {} unless params[:task].present?

    params.require(:task).permit(:title, :description, :status, :priority)
  end
end
