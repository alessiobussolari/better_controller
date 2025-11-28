# Utilities

BetterController includes several utility modules for common controller tasks.

## Parameter Validation

Include `BetterController::Utils::ParameterValidation` for parameter validation helpers.

### requires_params

Validate required parameters for specific actions:

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::ParameterValidation

  requires_params :create, :name, :email
  requires_params :update, :name
end
```

### param_schema

Define a validation schema for parameters:

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::ParameterValidation

  param_schema :create, {
    name: { required: true, type: String },
    email: { required: true, format: /@/ },
    age: { type: Integer },
    role: { in: %w[admin user guest] }
  }
end
```

**Schema options:**

| Option | Description |
|--------|-------------|
| `required` | Parameter must be present |
| `type` | Parameter must be of specified type |
| `in` | Parameter must be in allowed list |
| `format` | Parameter must match regex |

### Manual Validation

Validate in action methods:

```ruby
def create
  validate_required_params(:name, :email)
  # ...
end

def update
  validate_param_schema({
    name: { required: true },
    age: { type: Integer }
  })
  # ...
end
```

## Pagination

Include `BetterController::Utils::Pagination` for pagination support.

### Basic Usage

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::Pagination

  def index
    users = paginate(User.all)
    respond_with_pagination(users)
  end
end
```

### Configuration

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::Pagination

  configure_pagination enabled: true, per_page: 25

  def index
    users = paginate(User.all)
    # Uses configured per_page
  end
end
```

### Override Per Request

```ruby
def index
  users = paginate(User.all,
    page: params[:page],
    per_page: params[:per_page] || 50
  )
end
```

### Pagination Meta

Get pagination metadata:

```ruby
def index
  users = paginate(User.all)

  meta = pagination_meta(users)
  # => {
  #   current_page: 1,
  #   total_pages: 5,
  #   total_count: 100,
  #   per_page: 20
  # }
end
```

## Logging

Include `BetterController::Utils::Logging` for logging helpers.

### Log Levels

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::Logging

  def create
    log_debug('Starting user creation')
    log_info('Creating user', email: params[:email])
    log_warn('User already exists') if User.exists?(email: params[:email])
    log_error('Failed to create user', error: @error.message)
  end
end
```

### Exception Logging

```ruby
def create
  User.create!(user_params)
rescue => e
  log_exception(e, context: { user_email: params[:email] })
  raise
end
```

### Structured Logging

Pass additional context:

```ruby
log_info('User action',
  user_id: current_user.id,
  action: 'create',
  resource: 'User',
  ip: request.remote_ip
)
```

## Params Helpers

Include `BetterController::Utils::ParamsHelpers` for parameter manipulation.

### Safe Params Access

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::ParamsHelpers

  def index
    # Safe access with defaults
    page = param_value(:page, default: 1)
    per_page = param_value(:per_page, default: 25)
    sort = param_value(:sort, default: 'created_at')
  end
end
```

### Type Conversion

```ruby
# Convert to integer
user_id = param_as_integer(:user_id)

# Convert to boolean
active = param_as_boolean(:active)

# Convert to array
ids = param_as_array(:ids)
```

### Nested Params

```ruby
# Access nested params safely
address_city = nested_param(:user, :address, :city)
# Equivalent to: params.dig(:user, :address, :city)
```

## Combining Utilities

All utilities work together:

```ruby
class Api::UsersController < ApplicationController
  include BetterController::Utils::ParameterValidation
  include BetterController::Utils::Pagination
  include BetterController::Utils::Logging
  include BetterController::Utils::ParamsHelpers

  configure_pagination enabled: true, per_page: 25

  requires_params :create, :name, :email

  def index
    log_info('Listing users', page: params[:page])

    users = paginate(User.all)
    respond_with_pagination(users)
  end

  def create
    log_info('Creating user', email: params[:email])

    user = User.create!(user_params)
    respond_with_success(user, status: :created)
  rescue => e
    log_exception(e)
    respond_with_error(e, status: :unprocessable_entity)
  end
end
```

Or use the shortcut includes:

```ruby
# For API controllers (includes all utilities)
include BetterControllerApi

# For HTML controllers (includes all utilities + Turbo)
include BetterController
```
