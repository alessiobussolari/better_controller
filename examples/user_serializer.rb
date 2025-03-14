# frozen_string_literal: true

# Example of a serializer for User resources
class UserSerializer
  include BetterController::Serializer

  # Define the attributes to include in the serialized output
  attributes :id, :name, :email, :role, :created_at, :updated_at

  # Define methods to include in the serialized output
  methods :full_name, :active_status

  # Define associations to include in the serialized output
  # associations posts: PostSerializer, comments: CommentSerializer
end
