# frozen_string_literal: true

class ArticleSerializer
  include BetterController::Serializers::Serializer

  attributes :id, :title, :body, :published
end
