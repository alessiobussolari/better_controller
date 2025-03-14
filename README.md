# BetterController 🎮

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

> 🚀 A powerful Ruby gem for building standardized, maintainable, and feature-rich Rails controllers

BetterController simplifies the process of building RESTful controllers in your Rails applications. It provides a structured approach to define controllers, services, and serializers, making your development process more maintainable and efficient.

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

## Why BetterController? 🤔

- 🏗️ **Standardized Approach**: Consistent controller structure across your application
- 🧩 **Modular Design**:
  - Separate controller, service, and serializer components
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

Create a controller that inherits from the ResourcesController:

```ruby
class UsersController < BetterController::ResourcesController
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

Create a service class to handle business logic:

```ruby
class UserService
  def self.create(params)
    user = User.new(params)
    user.save
    user
  end
  
  def self.update(user, params)
    user.update(params)
    user
  end
  
  def self.destroy(user)
    user.destroy
    user
  end
end
```

### Serializer

Create a serializer to format your responses:

```ruby
class UserSerializer
  def self.serialize(user, options = {})
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
```

## Core Features

### ResourcesController

The `ResourcesController` provides a standardized implementation of RESTful actions:

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

The `Pagination` module provides pagination functionality for ActiveRecord collections:

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

end
```

## Advanced Customization

### Overriding Default Behavior

You can override any of the default methods in your controller to customize behavior:

```ruby
class UsersController < BetterController::ResourcesController
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
class UserSerializer
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

### Custom Error Handling

Implement custom error handling in your controllers:

```ruby
class ApplicationController < ActionController::Base
  include BetterController
  
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from CustomError::AuthorizationError, with: :handle_authorization_error
  
  private
  
  def handle_not_found(exception)
    respond_with_error(exception.message, status: :not_found, options: { code: 'NOT_FOUND' })
  end
  
  def handle_parameter_missing(exception)
    respond_with_error("Required parameter missing: #{exception.param}", status: :bad_request)
  end
  
  def handle_authorization_error(exception)
    respond_with_error('You are not authorized to perform this action', status: :forbidden)
  end
end
```

## Testing

BetterController includes RSpec tests to ensure functionality. Run the tests with:

```bash
bundle exec rspec
```

Example test for a controller:

```ruby
RSpec.describe UsersController, type: :controller do
  describe '#index' do
    it 'returns a collection of users' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data']).to be_an(Array)
    end
  end
  
  describe '#create' do
    it 'creates a new user' do
      post :create, params: { user: { name: 'John Doe', email: 'john@example.com' } }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['message']).to eq('User created successfully')
    end
  end
end
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Advanced Features

### Pagination

The `Pagination` module provides pagination functionality for ActiveRecord collections:

```ruby
def index
  execute_action do
    collection = User.all
    @users = paginate(collection, page: params[:page], per_page: 20)
    respond_with_success(@users)
  end
end
```

### Parameter Helpers

The `ParamsHelpers` module provides enhanced parameter handling:

```ruby
# Get a typed parameter
user_id = param(:user_id, type: :integer)

# Get a boolean parameter
active = boolean_param(:active, default: true)

# Get a date parameter
start_date = date_param(:start_date)

# Get a JSON parameter
data = json_param(:data)
```

### Logging

The `Logging` module provides enhanced logging capabilities:

```ruby
# Log at different levels
log_info("Processing request")
log_debug("Debug information")
log_warn("Warning message")
log_error("Error occurred")

# Log with tags
log_info("User created", { user_id: user.id, email: user.email })

# Log exceptions
begin
  # Some code that might raise an exception
rescue => e
  log_exception(e, { controller: self.class.name, action: action_name })
end
```

## Generators

### Controller Generator

Generate a controller with BetterController:

```bash
rails generate better_controller:controller Users index show create update destroy
```

This will create:
- A UsersController with the specified actions
- A UserService for handling business logic
- A UserSerializer for serializing responses

## Example Implementation

### Controller

```ruby
class UsersController < ApplicationController
  include BetterController::ResourcesController
  
  # GET /users
  def index
    execute_action do
      @resource_collection = resource_collection_resolver
      data = serialize_resource(@resource_collection, index_serializer)
      respond_with_success(data, options: { meta: meta })
    end
  end
  
  # GET /users/:id
  def show
    execute_action do
      @resource = resource_resolver
      data = serialize_resource(@resource, show_serializer)
      respond_with_success(data)
    end
  end
  
  # POST /users
  def create
    execute_action do
      @resource = resource_service.create(resource_params)
      data = serialize_resource(@resource, create_serializer)
      respond_with_success(data, status: :created)
    end
  end
  
  # PATCH/PUT /users/:id
  def update
    execute_action do
      @resource = resource_resolver
      resource_service.update(@resource, resource_params)
      data = serialize_resource(@resource, update_serializer)
      respond_with_success(data)
    end
  end
  
  # DELETE /users/:id
  def destroy
    execute_action do
      @resource = resource_resolver
      resource_service.destroy(@resource)
      respond_with_success(nil, status: :no_content)
    end
  end
  
  protected
  
  def resource_service_class
    UserService
  end
  
  def resource_params_root_key
    :user
  end
  
  def resource_serializer
    UserSerializer
  end
end
```

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
