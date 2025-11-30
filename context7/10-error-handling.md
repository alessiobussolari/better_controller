# Error Handling

Error handling patterns and Result class.

---

## Result Class

### Create Result

```ruby
result = BetterController::Result.new(resource, meta: { action: 'create' })
```

--------------------------------

### Check Status

```ruby
result.success?  # true if no errors
result.failure?  # true if has errors
```

--------------------------------

### Access Data

```ruby
result.resource  # The wrapped resource
result.meta      # Metadata hash
result.message   # Message from meta
result.errors    # Errors from resource
```

--------------------------------

## Configure Wrapped Responses

### Enable Result Unwrapping

```ruby
BetterController.configure do |config|
  config.wrapped_responses_class = BetterController::Result
end
```

--------------------------------

## Error Types in Action DSL

### Supported Types

```ruby
:validation    # ActiveRecord::RecordInvalid, ActiveModel::ValidationError
:not_found     # ActiveRecord::RecordNotFound
:authorization # Pundit::NotAuthorizedError, CanCan::AccessDenied
:any           # Catch-all for other errors
```

--------------------------------

### Handle by Type

```ruby
action :create do
  service Users::CreateService

  on_error :validation do
    html { render_page status: :unprocessable_entity }
    json { render json: { errors: @result[:errors] }, status: 422 }
  end

  on_error :not_found do
    html { redirect_to users_path, alert: 'Not found' }
    json { render json: { error: 'Not found' }, status: 404 }
  end

  on_error :authorization do
    html { redirect_to root_path, alert: 'Not authorized' }
    json { render json: { error: 'Forbidden' }, status: 403 }
  end

  on_error :any do
    html { redirect_to users_path, alert: 'An error occurred' }
  end
end
```

--------------------------------

## Error Status Mapping

### Status Codes

```ruby
:not_found     => :not_found           # 404
:authorization => :forbidden           # 403
:validation    => :unprocessable_entity # 422
:any           => :internal_server_error # 500
```

--------------------------------

## ServiceError

### Raised for Failed Results

```ruby
class BetterController::Errors::ServiceError < StandardError
  attr_reader :resource, :meta

  def message
    # Error message
  end

  def errors
    # Errors from resource
  end
end
```

--------------------------------

## Base Controller Error Handling

### execute_action

```ruby
def index
  execute_action do
    @users = User.all
    respond_with_success(@users)
  end
end

# Automatically handles:
# - ActiveRecord::RecordNotFound => 404
# - ActiveRecord::RecordInvalid => 422
# - Other exceptions => logged and re-raised
```

--------------------------------

## with_transaction

### Wrap in Transaction

```ruby
def create
  execute_action do
    with_transaction do
      @user = User.create!(user_params)
      @profile = @user.create_profile!(profile_params)
      respond_with_success(@user, status: :created)
    end
  end
end
```

--------------------------------

## Error Logging

### Automatic Logging

```ruby
BetterController.configure do |config|
  config.error_handling_log_errors = true
  config.error_handling_detailed_errors = true
end
```

--------------------------------

### Manual Logging

```ruby
begin
  risky_operation
rescue => e
  log_exception(e, context: 'operation_name', user_id: current_user.id)
  respond_with_error(e)
end
```

--------------------------------

## Error Response Format

### JSON Error Response

```json
{
  "data": {
    "error": {
      "type": "ActiveRecord::RecordInvalid",
      "message": "Validation failed: Name can't be blank"
    }
  },
  "meta": {
    "version": "v1"
  }
}
```

--------------------------------

### Validation Error Response

```json
{
  "data": {
    "error": {
      "messages": ["Name can't be blank", "Email is invalid"],
      "details": {
        "name": ["can't be blank"],
        "email": ["is invalid"]
      }
    }
  },
  "meta": {
    "version": "v1"
  }
}
```

--------------------------------

## Instance Variables

### Available After Error

```ruby
@error      # The exception
@error_type # :validation, :not_found, :authorization, :any
@result     # Service result (may contain errors)
```

--------------------------------

## Complete Example

### Error Handling in Action

```ruby
class UsersController < ApplicationController
  include BetterController

  action :create do
    service Users::CreateService
    params_key :user
    permit :name, :email

    on_success do
      html { redirect_to users_path, notice: 'Created!' }
      json { render json: @result[:resource], status: :created }
    end

    on_error :validation do
      html { render_page status: :unprocessable_entity }
      turbo_stream do
        replace :user_form, component: UserFormComponent
        form_errors errors: @result[:errors]
      end
      json { render json: { errors: @result[:errors] }, status: 422 }
    end

    on_error :any do
      log_exception(@error, action: 'create_user')
      html { redirect_to users_path, alert: 'An error occurred' }
      json { render json: { error: @error.message }, status: 500 }
    end
  end
end
```

--------------------------------
