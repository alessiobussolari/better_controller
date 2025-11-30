# Response Helpers

ResponseHelpers provides standardized methods for JSON API responses.

---

## Overview

The ResponseHelpers module provides `respond_with_success` and `respond_with_error` methods that format responses consistently.

## Response Format

All API responses follow this structure:

```json
{
  "data": { ... },
  "meta": {
    "version": "v1",
    ...
  }
}
```

The `version` is automatically included from `BetterController.config.api_version`.

## respond_with_success

Send a successful response:

```ruby
# Basic usage
respond_with_success(data)

# With custom status
respond_with_success(data, status: :created)

# With additional metadata
respond_with_success(data, meta: { total_count: 100 })

# Combined
respond_with_success(user.as_json, status: :created, meta: { created_at: Time.current })
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | Object | `nil` | The response data |
| `status` | Symbol/Integer | `:ok` | HTTP status code |
| `meta` | Hash | `{}` | Additional metadata |

### Examples

```ruby
# Simple response
respond_with_success({ id: 1, name: 'John' })
# => { "data": { "id": 1, "name": "John" }, "meta": { "version": "v1" } }

# With metadata
respond_with_success(users, meta: { page: 1, total: 50 })
# => { "data": [...], "meta": { "version": "v1", "page": 1, "total": 50 } }

# Created status
respond_with_success(new_user, status: :created)
# HTTP 201 Created
```

## respond_with_error

Send an error response:

```ruby
# Basic usage
respond_with_error(error)

# With custom status
respond_with_error(error, status: :not_found)

# With additional metadata
respond_with_error(error, meta: { request_id: '123' })
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `error` | Various | `nil` | The error (see formats below) |
| `status` | Symbol/Integer | `:unprocessable_entity` | HTTP status code |
| `meta` | Hash | `{}` | Additional metadata |

### Error Formats

The method handles multiple error types:

```ruby
# Exception
respond_with_error(StandardError.new('Something went wrong'))
# => { "data": { "error": { "type": "StandardError", "message": "Something went wrong" } }, ... }

# String
respond_with_error('Invalid input')
# => { "data": { "error": { "message": "Invalid input" } }, ... }

# Hash
respond_with_error({ code: 'INVALID', message: 'Bad request' })
# => { "data": { "error": { "code": "INVALID", "message": "Bad request" } }, ... }

# ActiveModel::Errors
respond_with_error(user.errors)
# => { "data": { "error": { "messages": ["Name can't be blank"], "details": { "name": ["can't be blank"] } } }, ... }
```

### Common Status Codes

| Symbol | Code | Use Case |
|--------|------|----------|
| `:ok` | 200 | Successful GET/PUT |
| `:created` | 201 | Successful POST |
| `:no_content` | 204 | Successful DELETE |
| `:bad_request` | 400 | Invalid request format |
| `:unauthorized` | 401 | Authentication required |
| `:forbidden` | 403 | Authorization denied |
| `:not_found` | 404 | Resource not found |
| `:unprocessable_entity` | 422 | Validation errors |
| `:internal_server_error` | 500 | Server error |

## Using in Controllers

### With ResourcesController

ResponseHelpers are automatically included:

```ruby
class Api::UsersController < ApplicationController
  include BetterController::Controllers::ResourcesController

  def custom_action
    user = User.find(params[:id])
    respond_with_success(serialize_resource(user))
  rescue ActiveRecord::RecordNotFound
    respond_with_error('User not found', status: :not_found)
  end
end
```

### Standalone Usage

Include the module directly:

```ruby
class Api::CustomController < ApplicationController
  include BetterController::Controllers::ResponseHelpers

  def status
    respond_with_success(
      { status: 'healthy', uptime: process_uptime },
      meta: { timestamp: Time.current.iso8601 }
    )
  end
end
```

## Customizing the Version

Set the API version in configuration:

```ruby
BetterController.configure do |config|
  config.api_version = 'v2'
end
```

All responses will then include `"version": "v2"` in the meta.

## Example Responses

### Success Response

```ruby
respond_with_success(
  { id: 1, name: 'Product', price: 29.99 },
  status: :ok,
  meta: { currency: 'USD' }
)
```

```json
{
  "data": {
    "id": 1,
    "name": "Product",
    "price": 29.99
  },
  "meta": {
    "version": "v1",
    "currency": "USD"
  }
}
```

### Error Response

```ruby
respond_with_error(
  product.errors,
  status: :unprocessable_entity,
  meta: { field_count: 2 }
)
```

```json
{
  "data": {
    "error": {
      "messages": [
        "Name can't be blank",
        "Price must be greater than 0"
      ],
      "details": {
        "name": ["can't be blank"],
        "price": ["must be greater than 0"]
      }
    }
  },
  "meta": {
    "version": "v1",
    "field_count": 2
  }
}
```
