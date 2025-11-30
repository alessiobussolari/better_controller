# Resources Controller

The ResourcesController module provides standardized RESTful CRUD actions for any ActiveRecord model.

---

## Overview

ResourcesController is a lightweight module that provides index, show, create, update, and destroy actions out of the box. It's designed to work with any ActiveRecord model without requiring services or serializers.

## Basic Usage

```ruby
class UsersController < ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    User
  end

  def resource_params
    params.require(:user).permit(:name, :email, :role)
  end
end
```

That's it! You now have a fully functional RESTful controller.

## Required Methods

### resource_class

Returns the ActiveRecord model class:

```ruby
def resource_class
  User
end
```

### resource_params

Returns permitted strong parameters:

```ruby
def resource_params
  params.require(:user).permit(:name, :email, :password)
end
```

## Optional Overrides

### resource_scope

Customize the base scope for queries:

```ruby
# Default implementation
def resource_scope
  resource_class.all
end

# Scoped to current user
def resource_scope
  current_user.organization.users
end

# With default ordering
def resource_scope
  User.order(created_at: :desc)
end
```

### serialize_resource

Customize single resource serialization:

```ruby
# Default implementation
def serialize_resource(resource)
  resource.as_json
end

# With specific attributes
def serialize_resource(resource)
  resource.as_json(only: [:id, :name, :email])
end

# Using a serializer gem
def serialize_resource(resource)
  UserSerializer.new(resource).as_json
end
```

### serialize_collection

Customize collection serialization:

```ruby
# Default implementation
def serialize_collection(collection)
  collection.map { |r| serialize_resource(r) }
end

# With pagination metadata
def serialize_collection(collection)
  {
    users: collection.map { |r| serialize_resource(r) },
    total: collection.total_count
  }
end
```

### Metadata Methods

Add custom metadata to responses:

```ruby
def index_meta
  { total_count: resource_scope.count }
end

def show_meta
  { last_updated: @resource.updated_at }
end

def create_meta
  { created_at: Time.current }
end

def update_meta
  {}
end

def destroy_meta
  { deleted_at: Time.current }
end
```

## Provided Actions

### index

Lists all resources:

```ruby
def index
  execute_action do
    @resources = resource_scope.all
    respond_with_success(serialize_collection(@resources), meta: index_meta)
  end
end
```

### show

Displays a single resource:

```ruby
def show
  execute_action do
    @resource = find_resource
    respond_with_success(serialize_resource(@resource), meta: show_meta)
  end
end
```

### create

Creates a new resource:

```ruby
def create
  execute_action do
    @resource = resource_scope.new(resource_params)

    if @resource.save
      respond_with_success(serialize_resource(@resource), status: :created, meta: create_meta)
    else
      respond_with_error(@resource.errors, status: :unprocessable_entity)
    end
  end
end
```

### update

Updates an existing resource:

```ruby
def update
  execute_action do
    @resource = find_resource

    if @resource.update(resource_params)
      respond_with_success(serialize_resource(@resource), meta: update_meta)
    else
      respond_with_error(@resource.errors, status: :unprocessable_entity)
    end
  end
end
```

### destroy

Deletes a resource:

```ruby
def destroy
  execute_action do
    @resource = find_resource

    if @resource.destroy
      respond_with_success(serialize_resource(@resource), meta: destroy_meta)
    else
      respond_with_error(@resource.errors, status: :unprocessable_entity)
    end
  end
end
```

## Response Format

All responses follow a standard format:

```json
{
  "data": { ... },
  "meta": {
    "version": "v1",
    ...
  }
}
```

Error responses:

```json
{
  "data": {
    "error": {
      "messages": ["Name can't be blank"],
      "details": { "name": ["can't be blank"] }
    }
  },
  "meta": {
    "version": "v1"
  }
}
```

## Included Modules

ResourcesController automatically includes:

- `BetterController::Controllers::Base` - Error handling and transactions
- `BetterController::Controllers::ResponseHelpers` - Response formatting
- `BetterController::Utils::ParameterValidation` - Parameter validation
- `BetterController::Utils::Logging` - Enhanced logging

## Complete Example

```ruby
class Api::V1::ProductsController < Api::ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Product
  end

  def resource_scope
    current_user.company.products.active
  end

  def resource_params
    params.require(:product).permit(:name, :price, :category_id, :description)
  end

  def serialize_resource(resource)
    {
      id: resource.id,
      name: resource.name,
      price: resource.price.to_f,
      category: resource.category&.name,
      created_at: resource.created_at.iso8601
    }
  end

  def index_meta
    { total_products: resource_scope.count }
  end
end
```
