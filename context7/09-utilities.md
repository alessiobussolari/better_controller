# Utilities

Pagination, parameter helpers, validation, and logging.

---

## Pagination

### paginate

```ruby
def index
  @users = paginate(User.all)
  @users = paginate(User.all, page: 2, per_page: 50)
end
```

--------------------------------

### pagination_meta

```ruby
meta = pagination_meta(@users)
# => { current_page: 1, total_pages: 10, total_count: 250, per_page: 25 }
```

--------------------------------

### pagination_links

```ruby
links = pagination_links(@users)
# => { self: "...", first: "...", last: "...", prev: "...", next: "..." }
```

--------------------------------

### configure_pagination

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::Pagination

  configure_pagination per_page: 50
end
```

--------------------------------

## Parameter Helpers

### param (Universal)

```ruby
value = param(:name)
id = param(:id, type: :integer)
active = param(:active, type: :boolean)
date = param(:date, type: :date)
page = param(:page, type: :integer, default: 1)
email = param(:email, required: true)
```

--------------------------------

### Supported Types

```ruby
:integer, Integer    # to_i
:float, Float        # to_f
:string, String      # to_s
:boolean, :bool      # ActiveModel boolean
:date, Date          # Date.parse
:datetime, Time      # Time.parse
:array, Array        # Array coercion
:hash, Hash          # Hash preservation
:json, :JSON         # JSON.parse
```

--------------------------------

### boolean_param

```ruby
active = boolean_param(:active)
active = boolean_param(:active, default: false)
```

--------------------------------

### integer_param

```ruby
page = integer_param(:page)
page = integer_param(:page, default: 1)
```

--------------------------------

### float_param

```ruby
price = float_param(:price)
```

--------------------------------

### date_param

```ruby
start_date = date_param(:start_date)
```

--------------------------------

### datetime_param

```ruby
created_at = datetime_param(:created_at)
```

--------------------------------

### array_param

```ruby
ids = array_param(:ids)
ids = array_param(:ids, default: [])
```

--------------------------------

### json_param

```ruby
settings = json_param(:settings)
settings = json_param(:settings, default: {})
```

--------------------------------

### hash_param

```ruby
options = hash_param(:options)
options = hash_param(:options, default: {})
```

--------------------------------

## Parameter Validation

### validate_required_params

```ruby
def create
  validate_required_params(:name, :email)
end
```

--------------------------------

### validate_param_schema

```ruby
validate_param_schema(
  name: { required: true, type: String },
  email: { required: true, format: /\A[\w+\-.]+@[\w\-]+\.[a-z]+\z/i },
  age: { type: Integer, in: 18..120 },
  role: { in: ['admin', 'user'] }
)
```

--------------------------------

### Class-Level Validation

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::ParameterValidation

  requires_params :create, :name, :email

  param_schema :create, {
    name: { required: true },
    email: { required: true, format: URI::MailTo::EMAIL_REGEXP }
  }
end
```

--------------------------------

## Logging

### Log Methods

```ruby
log_info('User created', user_id: 123)
log_debug('Processing', params: params.to_h)
log_warn('Rate limit', remaining: 10)
log_error('Failed', error: error.message)
log_fatal('System failure', details: '...')
```

--------------------------------

### log_exception

```ruby
begin
  risky_operation
rescue => e
  log_exception(e, context: 'user_creation', user_id: 123)
end
```

--------------------------------

### Custom Logger

```ruby
BetterController::Utils::Logging.logger = Rails.logger
```

--------------------------------

## Complete Example

### Controller with Utilities

```ruby
class Api::UsersController < Api::ApplicationController
  include BetterController::Utils::Pagination
  include BetterController::Utils::ParamsHelpers
  include BetterController::Utils::ParameterValidation
  include BetterController::Utils::Logging

  configure_pagination per_page: 20

  def index
    log_info('Fetching users', page: integer_param(:page, default: 1))

    active_only = boolean_param(:active, default: true)
    @users = active_only ? User.active : User.all
    @users = paginate(@users)

    respond_with_success(
      serialize_collection(@users),
      meta: pagination_meta(@users)
    )
  end

  def create
    validate_required_params(:name, :email)

    @user = User.create!(user_params)
    log_info('User created', user_id: @user.id)

    respond_with_success(serialize_resource(@user), status: :created)
  rescue => e
    log_exception(e)
    respond_with_error(e)
  end
end
```

--------------------------------
