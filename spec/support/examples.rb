# frozen_string_literal: true

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
end

class ExampleService < BetterController::Service
  def model_class
    ExampleModel
  end

  def permitted_attributes
    [:name, :email]
  end

  def list_query
    [
      ExampleModel.new(id: 1, name: 'Example 1', email: 'example1@example.com'),
      ExampleModel.new(id: 2, name: 'Example 2', email: 'example2@example.com'),
      ExampleModel.new(id: 3, name: 'Example 3', email: 'example3@example.com')
    ]
  end

  def find_query(id)
    ExampleModel.new(id: id, name: "Example #{id}", email: "example#{id}@example.com")
  end

  def create(attributes)
    model = model_class.new(attributes)
    model.valid? ? model : raise_validation_error(model)
  end

  def update(resource, attributes)
    resource.attributes = attributes
    resource.valid? ? resource : raise_validation_error(resource)
  end

  def destroy(resource)
    resource
  end

  private

  def raise_validation_error(model)
    raise ActiveModel::ValidationError.new(model)
  end
end

class ExampleSerializer
  include BetterController::Serializer

  attributes :id, :name, :email, :created_at, :updated_at
  
  methods :full_name
  
  def full_name
    "#{object.name} (#{object.email})"
  end
end
