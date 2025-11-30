# frozen_string_literal: true

class ExampleSerializer
  include BetterController::Serializers::Serializer

  attributes :id, :name, :email
end
