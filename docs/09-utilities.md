# Utilities

BetterController provides utility modules for pagination, parameter handling, validation, and logging.

---

## Pagination

The Pagination module provides Kaminari-based pagination with metadata.

### paginate

Paginate a collection:

```ruby
def index
  @users = paginate(User.all)
  # or with options
  @users = paginate(User.all, page: 2, per_page: 50)
end
```

Parameters are read from `params[:page]` and `params[:per_page]` by default.

### pagination_meta

Get pagination metadata:

```ruby
meta = pagination_meta(@users)
# => {
#   current_page: 1,
#   total_pages: 10,
#   total_count: 250,
#   per_page: 25
# }
```

### pagination_links

Get pagination URLs:

```ruby
links = pagination_links(@users)
# => {
#   self: "http://example.com/users?page=2",
#   first: "http://example.com/users?page=1",
#   last: "http://example.com/users?page=10",
#   prev: "http://example.com/users?page=1",
#   next: "http://example.com/users?page=3"
# }
```

### configure_pagination

Set defaults at the controller level:

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::Pagination

  configure_pagination per_page: 50
end
```

---

## Parameter Helpers

The ParamsHelpers module provides type-casting for parameters.

### param

Universal parameter getter with type casting:

```ruby
# Basic usage
value = param(:name)

# With type casting
id = param(:id, type: :integer)
price = param(:price, type: :float)
active = param(:active, type: :boolean)
date = param(:start_date, type: :date)
time = param(:created_at, type: :datetime)
tags = param(:tags, type: :array)
settings = param(:settings, type: :hash)
data = param(:data, type: :json)

# With default value
page = param(:page, type: :integer, default: 1)

# Required parameter (raises ActionController::ParameterMissing)
email = param(:email, required: true)
```

### Supported Types

| Type | Aliases | Conversion |
|------|---------|------------|
| `:integer` | `Integer` | `to_i` |
| `:float` | `Float` | `to_f` |
| `:string` | `String` | `to_s` |
| `:boolean` | `:bool` | ActiveModel boolean cast |
| `:date` | `Date` | `Date.parse` |
| `:datetime` | `DateTime`, `Time` | `Time.parse` |
| `:array` | `Array` | Array coercion |
| `:hash` | `Hash` | Hash preservation |
| `:json` | `:JSON` | `JSON.parse` |

### Convenience Methods

```ruby
# Boolean
active = boolean_param(:active)
active = boolean_param(:active, default: false)

# Integer
page = integer_param(:page)
page = integer_param(:page, default: 1)

# Float
price = float_param(:price)

# Date
start_date = date_param(:start_date)

# DateTime
created_at = datetime_param(:created_at)

# Array
ids = array_param(:ids)
ids = array_param(:ids, default: [])

# JSON
settings = json_param(:settings)
settings = json_param(:settings, default: {})

# Hash
options = hash_param(:options)
```

---

## Parameter Validation

The ParameterValidation module provides validation helpers.

### validate_required_params

Ensure parameters are present:

```ruby
def create
  validate_required_params(:name, :email)
  # Raises ActionController::ParameterMissing if missing
end
```

### validate_param_schema

Validate parameters against a schema:

```ruby
def create
  validate_param_schema(
    name: { required: true, type: String },
    email: { required: true, format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i },
    age: { type: Integer, in: 18..120 },
    role: { in: ['admin', 'user', 'guest'] }
  )
end
```

### Schema Options

| Option | Description |
|--------|-------------|
| `required` | Parameter must be present |
| `type` | Expected type (Class) |
| `in` | Allowed values (Array or Range) |
| `format` | Regex pattern |

### Class-Level Validation

Define validation rules at the class level:

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::ParameterValidation

  requires_params :create, :name, :email
  requires_params :update, :id

  param_schema :create, {
    name: { required: true },
    email: { required: true, format: URI::MailTo::EMAIL_REGEXP },
    role: { in: ['admin', 'user'] }
  }
end
```

---

## Logging

The Logging module provides enhanced logging with tags.

### Log Methods

```ruby
log_info('User created', user_id: 123)
log_debug('Processing request', params: params.to_h)
log_warn('Rate limit approaching', remaining: 10)
log_error('Failed to process', error: error.message)
log_fatal('System failure', details: '...')
```

### log_exception

Log exceptions with backtrace:

```ruby
begin
  risky_operation
rescue => e
  log_exception(e, context: 'user_creation', user_id: 123)
end
```

Output includes:
- Controller name
- Action name
- Exception class
- Message
- Backtrace

### Automatic Tags

All log methods automatically include:
- `controller`: Controller class name
- `action`: Current action name

### Custom Logger

Set a custom logger:

```ruby
BetterController::Utils::Logging.logger = Rails.logger
BetterController::Utils::Logging.logger = MyCustomLogger.new
```

---

## Complete Example

```ruby
class Api::UsersController < Api::ApplicationController
  include BetterController::Utils::Pagination
  include BetterController::Utils::ParamsHelpers
  include BetterController::Utils::ParameterValidation
  include BetterController::Utils::Logging

  configure_pagination per_page: 20

  requires_params :create, :name, :email

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
    validate_param_schema(
      name: { required: true },
      email: { required: true, format: URI::MailTo::EMAIL_REGEXP },
      age: { type: Integer }
    )

    @user = User.create!(user_params)
    log_info('User created', user_id: @user.id)

    respond_with_success(serialize_resource(@user), status: :created)
  rescue ActiveRecord::RecordInvalid => e
    log_exception(e, context: 'user_creation')
    respond_with_error(e.record.errors)
  end

  def search
    query = param(:q, required: true)
    limit = integer_param(:limit, default: 10)
    include_inactive = boolean_param(:include_inactive, default: false)

    @users = User.search(query).limit(limit)
    @users = @users.active unless include_inactive

    respond_with_success(serialize_collection(@users))
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :age)
  end
end
```
