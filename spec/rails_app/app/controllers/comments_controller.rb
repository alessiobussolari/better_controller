# frozen_string_literal: true

class CommentsController < ApplicationController
  include BetterController::Controllers::ResourcesController

  before_action :set_article

  private

  def set_article
    @article = Article.find(params[:article_id])
  end

  def resource_class
    Comment
  end

  # Override resource_scope to scope to article's comments
  def resource_scope
    @article.comments
  end

  def resource_params
    params.require(:comment).permit(:author, :body)
  end
end
