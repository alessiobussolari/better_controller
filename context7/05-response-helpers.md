# Response Helpers

Standardized API response methods.

---

## Response Format

### Standard Structure

```json
{
  "data": { ... },
  "meta": { "version": "v1" }
}
```

--------------------------------

## respond_with_success

### Basic Usage

```ruby
respond_with_success(data)
```

--------------------------------

### With Status

```ruby
respond_with_success(data, status: :created)
respond_with_success(data, status: :ok)
```

--------------------------------

### With Metadata

```ruby
respond_with_success(data, meta: { total: 100, page: 1 })
```

--------------------------------

### Combined

```ruby
respond_with_success(
  user.as_json,
  status: :created,
  meta: { created_at: Time.current }
)
```

--------------------------------

## respond_with_error

### Basic Usage

```ruby
respond_with_error(error)
respond_with_error('Something went wrong')
```

--------------------------------

### With Status

```ruby
respond_with_error(error, status: :not_found)
respond_with_error(error, status: :forbidden)
```

--------------------------------

### With ActiveModel::Errors

```ruby
respond_with_error(user.errors, status: :unprocessable_entity)
# => { data: { error: { messages: [...], details: {...} } }, meta: {...} }
```

--------------------------------

### Error Formats

```ruby
# Exception
respond_with_error(StandardError.new('Error'))
# => { error: { type: "StandardError", message: "Error" } }

# String
respond_with_error('Invalid input')
# => { error: { message: "Invalid input" } }

# Hash
respond_with_error({ code: 'INVALID', message: 'Bad' })
# => { error: { code: "INVALID", message: "Bad" } }

# ActiveModel::Errors
respond_with_error(user.errors)
# => { error: { messages: [...], details: {...} } }
```

--------------------------------

## Common Status Codes

### Success Statuses

```ruby
:ok                    # 200
:created               # 201
:no_content            # 204
```

--------------------------------

### Error Statuses

```ruby
:bad_request           # 400
:unauthorized          # 401
:forbidden             # 403
:not_found             # 404
:unprocessable_entity  # 422
:internal_server_error # 500
```

--------------------------------

## Include Module

### In Controller

```ruby
class Api::CustomController < ApplicationController
  include BetterController::Controllers::ResponseHelpers

  def status
    respond_with_success(
      { status: 'healthy' },
      meta: { timestamp: Time.current.iso8601 }
    )
  end
end
```

--------------------------------

## Example Responses

### Success Response

```ruby
respond_with_success({ id: 1, name: 'Product' }, meta: { currency: 'USD' })
```

```json
{
  "data": { "id": 1, "name": "Product" },
  "meta": { "version": "v1", "currency": "USD" }
}
```

--------------------------------

### Error Response

```ruby
respond_with_error(product.errors, status: :unprocessable_entity)
```

```json
{
  "data": {
    "error": {
      "messages": ["Name can't be blank"],
      "details": { "name": ["can't be blank"] }
    }
  },
  "meta": { "version": "v1" }
}
```

--------------------------------
