# frozen_string_literal: true

class ArticlesController < ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Article
  end

  def resource_params
    params.require(:article).permit(:title, :body, :published)
  end
end
