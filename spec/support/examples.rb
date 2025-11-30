# frozen_string_literal: true

# Mock service class for DSL tests
# This is NOT the removed BetterController::Services::Service -
# it's just a plain class used for testing the action DSL
class ExampleService
  def self.call(*_args)
    { success: true }
  end

  def call(*_args)
    { success: true }
  end
end

# Test model for unit tests
class ExampleModel
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :id, :integer
  attribute :name, :string
  attribute :email, :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  validates :name, presence: true
  validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }

  def initialize(attributes = {})
    super
    @id ||= 1
    @created_at ||= Time.current
    @updated_at ||= Time.current
  end

  def as_json(_options = {})
    {
      id:         id,
      name:       name,
      email:      email,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
