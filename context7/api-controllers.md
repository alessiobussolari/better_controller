# API Controllers

BetterController provides helpers for building JSON APIs with standardized responses.

## Basic Setup

Include `BetterControllerApi` in your API controllers:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  def index
    users = User.all
    respond_with_success(users)
  end

  def show
    user = User.find(params[:id])
    respond_with_success(user)
  rescue ActiveRecord::RecordNotFound => e
    respond_with_error(e, status: :not_found)
  end

  def create
    user = User.create!(user_params)
    respond_with_success(user, status: :created)
  rescue ActiveRecord::RecordInvalid => e
    respond_with_error(e, status: :unprocessable_entity)
  end
end
```

## Response Helpers

### respond_with_success

Return a success response:

```ruby
respond_with_success(data)
respond_with_success(data, status: :created)
respond_with_success(data, message: 'User created')
```

**Response format:**

```json
{
  "success": true,
  "data": { "id": 1, "name": "John" }
}
```

### respond_with_error

Return an error response:

```ruby
respond_with_error(exception)
respond_with_error(exception, status: :not_found)
respond_with_error("Custom error message", status: :bad_request)
```

**Response format:**

```json
{
  "success": false,
  "error": {
    "type": "ActiveRecord::RecordNotFound",
    "message": "Couldn't find User with id=999"
  }
}
```

### respond_with_pagination

Return a paginated response:

```ruby
def index
  users = paginate(User.all)
  respond_with_pagination(users)
end
```

**Response format:**

```json
{
  "success": true,
  "data": [...],
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 100,
      "per_page": 20
    }
  }
}
```

## Included Modules

`BetterControllerApi` includes these modules:

| Module | Purpose |
|--------|---------|
| `Controllers::Base` | Core functionality |
| `Controllers::ResponseHelpers` | Response helpers |
| `Utils::ParameterValidation` | Parameter validation |
| `Utils::ParamsHelpers` | Params helpers |
| `Utils::Logging` | Logging utilities |
| `Utils::Pagination` | Pagination support |
| `Controllers::ActionHelpers` | Standard actions |

## Parameter Validation

Validate required parameters:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  requires_params :create, :name, :email

  def create
    # Automatically validates :name and :email are present
    user = User.create!(user_params)
    respond_with_success(user, status: :created)
  end
end
```

Use schema validation:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  param_schema :update, {
    name: { required: true, type: String },
    age: { type: Integer },
    role: { in: %w[admin user guest] }
  }
end
```

## Pagination

Enable pagination in your controller:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  configure_pagination enabled: true, per_page: 25

  def index
    users = paginate(User.all)
    respond_with_pagination(users)
  end
end
```

## Error Handling

Standard error handling pattern:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  rescue_from ActiveRecord::RecordNotFound do |e|
    respond_with_error(e, status: :not_found)
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    respond_with_error(e, status: :unprocessable_entity)
  end

  rescue_from ActionController::ParameterMissing do |e|
    respond_with_error(e, status: :bad_request)
  end
end
```

## Standard Actions

Use standard CRUD actions:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  standard_actions User, paginate: true

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end
end
```

This generates: `index`, `show`, `create`, `update`, `destroy` actions.

## Logging

Built-in logging helpers:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  def create
    log_info('Creating user', user_email: params[:email])
    # ...
  rescue => e
    log_exception(e)
    raise
  end
end
```
