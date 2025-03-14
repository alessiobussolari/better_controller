# BetterController 🎮

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

> 🚀 A powerful Ruby gem for building standardized, maintainable, and feature-rich Rails controllers

BetterController simplifies the process of building RESTful controllers in your Rails applications. It provides a structured approach to define controllers, services, and serializers, making your development process more maintainable and efficient. With standardized API responses and robust serialization, your APIs will be consistent and easy to consume.

## ✨ Key Features

- 🏗️ **Standardized Controller Structure**: Define RESTful controllers with minimal code
- 🛠️ **Service Layer**: Separate business logic from controllers
- 📦 **Serialization**: Standardized JSON serialization for your resources
- 📄 **Pagination**: Built-in pagination support for collections
- 🔍 **Parameter Validation**: Robust parameter validation and type casting
- 🔄 **Response Handling**: Consistent JSON responses with standardized structure
- 🚨 **Error Handling**: Comprehensive error handling with custom error classes
- 📝 **Logging**: Enhanced logging capabilities
- 🧩 **Generators**: Rails generators for controllers, services, and serializers
- 📚 **Comprehensive Documentation**: Detailed guides for API responses and serializers

## Why BetterController? 🤔

- 🏗️ **Standardized Approach**: Consistent controller structure across your application
- 🧩 **Modular Design**:
  - Organized into controllers, services, serializers, and utilities
  - Reusable modules
  - Configurable behavior
- 🔄 **Flexible Implementation**:
  - Override default behavior when needed
  - Customize actions and responses
  - Extend with your own functionality
- ✅ **Robust Error Handling**:
  - Standardized error responses
  - Detailed error logging
  - Custom error classes
- 📊 **Enhanced Responses**:
  - Consistent JSON structure
  - Pagination metadata
  - Custom response formatting
- 📚 **Developer-Friendly**:
  - Comprehensive documentation
  - Predictable API behavior
  - Clear integration examples

## Installation

Add the gem to your Gemfile:

```ruby
gem 'better_controller'
```

Then run:

```bash
bundle install
```

Or install the gem manually:

```bash
gem install better_controller
```

## Configuration

In a Rails application, you can create an initializer by running:

```bash
rails generate better_controller:install
```

This command creates the file `config/initializers/better_controller.rb` with a default configuration. An example configuration is:

```ruby
BetterController.configure do |config|
  # Pagination configuration
  config[:pagination] = {
    enabled: true,
    per_page: 25
  }

  # Serialization configuration
  config[:serialization] = {
    include_root: false,
    camelize_keys: true
  }

  # Error handling configuration
  config[:error_handling] = {
    log_errors: true,
    detailed_errors: true
  }
end
```

## Generators

BetterController provides several generators to help you quickly scaffold your application:

### Install Generator

Creates an initializer with default configuration:

```bash
rails generate better_controller:install
```

### Controller Generator

Generates a controller with optional service and serializer:

```bash
rails generate better_controller:controller Users index show create update destroy
```

Options:
- `--skip-service`: Skip generating a service class
- `--skip-serializer`: Skip generating a serializer class
- `--model=MODEL_NAME`: Specify a custom model name (defaults to singular of controller name)

This will create:
- `app/controllers/users_controller.rb`
- `app/services/user_service.rb` (unless `--skip-service` is specified)
- `app/serializers/user_serializer.rb` (unless `--skip-serializer` is specified)

## Basic Usage

### Controller Setup

Include BetterController in your ApplicationController:

```ruby
class ApplicationController < ActionController::Base
  include BetterController
end
```

### Creating a ResourcesController

Create a controller that includes the ResourcesController module:

```ruby
class UsersController < ApplicationController
  include BetterController::Controllers::ResourcesController
  # Controller-specific configuration
  def resource_class
    User
  end
  
  def resource_params
    params.require(:user).permit(:name, :email, :role)
  end
  
  def resource_creator
    UserService.create(resource_params)
  end
  
  def resource_updater
    UserService.update(@resource, resource_params)
  end
  
  def resource_destroyer
    UserService.destroy(@resource)
  end
  
  def index_serializer
    UserSerializer
  end
  
  def show_serializer
    UserSerializer
  end
  
  def create_serializer
    UserSerializer
  end
  
  def update_serializer
    UserSerializer
  end
  
  def destroy_serializer
    UserSerializer
  end
  
  def create_message
    'User created successfully'
  end
  
  def update_message
    'User updated successfully'
  end
  
  def destroy_message
    'User deleted successfully'
  end
end
```

### Service Layer

Create a service class that inherits from the Service base class:

```ruby
class UserService < BetterController::Services::Service
  def model_class
    User
  end
  
  def permitted_attributes
    [:name, :email, :role]
  end
  
  # Override default methods as needed
  def create(attributes)
    # Custom creation logic
    user = model_class.new(attributes)
    # Additional operations...
    user.save!
    user
  end
  
  def update(resource, attributes)
    # Custom update logic
    resource.assign_attributes(attributes)
    # Additional operations...
    resource.save!
    resource
  end
  
  def destroy(resource)
    # Custom destroy logic
    # Additional operations before destroy...
    resource.destroy
    resource
  end
end
```

### Serialization

Create a serializer class that includes the Serializer module:

```ruby
class UserSerializer
  include BetterController::Serializers::Serializer
  
  # Define attributes to include in the serialized output
  attributes :id, :name, :email, :created_at
  
  # Define methods to include in the serialized output
  methods :full_name, :role_name
  
  def full_name
    "#{object.first_name} #{object.last_name}"
  end
  
  def role_name
    object.role.name if object.role
  end
end
```

## Documentation

BetterController includes comprehensive documentation to help you understand and use the library effectively:

- [API Responses](docs/api_responses.md): Detailed guide on the format of API responses
- [Serializers](docs/serializers.md): Guide on how to use serializers effectively

These documents provide in-depth information about how the system responds to requests and what client applications should expect.

## Core Features

### ResourcesController

The `BetterController::Controllers::ResourcesController` module provides a standardized implementation of RESTful actions:

```ruby
# Available actions
index   # GET /resources
show    # GET /resources/:id
create  # POST /resources
update  # PUT/PATCH /resources/:id
destroy # DELETE /resources/:id
```

### Response Handling

BetterController provides standardized methods for handling responses:

```ruby
# Success response
respond_with_success(data, options = {})

# Error response
respond_with_error(errors, options = {})
```

Example response format:

```json
{
  "data": { ... },
  "message": "Operation completed successfully",
  "meta": { ... }
}
```

### Pagination

The `BetterController::Utils::Pagination` module provides pagination functionality for ActiveRecord collections:

```ruby
def index
  execute_action do
    collection = paginate(resource_collection_resolver)
    data = serialize_collection(collection, index_serializer)
    respond_with_success(data, options: { meta: meta })
  end
end
```

Pagination metadata is included in the response:

```json
{
  "data": [ ... ],
  "meta": {
    "pagination": {
      "total_count": 100,
      "total_pages": 4,
      "current_page": 1,
      "per_page": 25
    }
  }
}
```

### Error Handling

BetterController provides comprehensive error handling:

```ruby
begin
  # Your code here
rescue ActiveRecord::RecordNotFound => e
  respond_with_error(e.message, status: :not_found)
rescue ActionController::ParameterMissing => e
  respond_with_error(e.message, status: :bad_request)
rescue StandardError => e
  respond_with_error(e.message, status: :internal_server_error)
end
```

Error response format:

```json
{
  "errors": {
    "base": ["Resource not found"]
  },
  "message": "An error occurred",
  "status": 404
}
```

## Advanced Customization

### Overriding Default Behavior

You can override any of the default methods in your controller to customize behavior:

```ruby
class UsersController < ApplicationController
  include BetterController::Controllers::ResourcesController
  
  # Override the default index action
  def index
    execute_action do
      @users = User.where(active: true)
      data = serialize_collection(@users, index_serializer)
      respond_with_success(data, options: { meta: { active_count: @users.count } })
    end
  end
  
  # Override the resource finder method
  def resource_finder
    User.includes(:posts, :comments).find(params[:id])
  end
  
  # Add custom actions
  def activate
    execute_action do
      @resource = resource_finder
      @resource.update(active: true)
      data = serialize_resource(@resource, show_serializer)
      respond_with_success(data, options: { message: 'User activated successfully' })
    end
  end
end
```

### Custom Serialization

You can implement custom serialization logic:

```ruby
class UserSerializer < BetterController::Serializers::Serializer
  def self.serialize(user, options = {})
    serialized = {
      id: user.id,
      name: user.name,
      email: user.email
    }
    
    # Add additional fields based on options
    if options[:include_details]
      serialized.merge!({
        role: user.role,
        last_login: user.last_login,
        created_at: user.created_at
      })
    end
    
    serialized
  end
  
  def self.serialize_collection(users, options = {})
    users.map { |user| serialize(user, options) }
  end
end
```

### Parameter Validation

The `BetterController::Utils::ParameterValidation` module provides robust parameter validation:

```ruby
def create
  execute_action do
    validate_parameters do
      required(:user).schema do
        required(:name).filled(:string)
        required(:email).filled(:string)
        optional(:role).maybe(:string)
      end
    end
    
    resource = resource_creator
    data = serialize_resource(resource, create_serializer)
    respond_with_success(data, options: { message: create_message })
  end
end
```

### Transaction Handling

The `with_transaction` method simplifies database transaction handling:

```ruby
def create
  execute_action do
    with_transaction do
      # All database operations within this block will be wrapped in a transaction
      user = User.create!(user_params)
      user.profile.create!(profile_params)
      user.settings.create!(settings_params)
      user
    end
  end
end
```

## Testing

BetterController is designed to be easily testable. Here are some examples of how to test your controllers:

### Controller Tests

Example test for a controller:

```ruby
RSpec.describe UsersController, type: :controller do
  describe '#index' do
    it 'returns a list of users' do
      get :index
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']).to be_an(Array)
    end
  end
  
  describe '#show' do
    it 'returns a user' do
      user = create(:user)
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(user.id)
    end
    
    it 'returns 404 for non-existent user' do
      get :show, params: { id: 999 }
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe '#create' do
    it 'creates a user' do
      user_params = { name: 'John Doe', email: 'john@example.com' }
      post :create, params: { user: user_params }
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['data']['name']).to eq('John Doe')
    end
    
    it 'returns 422 for invalid params' do
      post :create, params: { user: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

### Service Tests

Example test for a service:

```ruby
RSpec.describe UserService do
  describe '.create' do
    it 'creates a user' do
      params = { name: 'John Doe', email: 'john@example.com' }
      user = UserService.create(params)
      expect(user).to be_persisted
      expect(user.name).to eq('John Doe')
    end
    
    it 'returns user with errors if invalid' do
      params = { name: '' }
      user = UserService.create(params)
      expect(user).not_to be_persisted
      expect(user.errors).to be_present
    end
  end
end
```

## Contributing

Contributions are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Submit a pull request

Please make sure your code follows the [Ruby Style Guide](https://github.com/rubocop/rubocop) and includes appropriate tests.

## Contact and Support

- **GitHub**: [https://github.com/yourusername/better_controller](https://github.com/yourusername/better_controller)
- **Issues**: [https://github.com/yourusername/better_controller/issues](https://github.com/yourusername/better_controller/issues)
- **Email**: your.email@example.com

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
