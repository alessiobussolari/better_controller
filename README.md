# BetterController

[![Gem Version](https://badge.fury.io/rb/better_controller.svg)](https://badge.fury.io/rb/better_controller)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org)

A Ruby gem for building modern Rails controllers with a declarative DSL, Hotwire/Turbo support, and ViewComponent integration.

## Features

- **Declarative Action DSL** - Define controller actions with a clean, expressive syntax
- **Hotwire/Turbo Support** - Built-in support for Turbo Frames and Turbo Streams
- **ViewComponent Integration** - Seamless rendering of ViewComponents with page configurations
- **Service Layer Pattern** - First-class support for service objects
- **Flexible Response Handling** - Unified handling of HTML, Turbo Stream, and JSON responses
- **Error Handling** - Comprehensive error classification and response formatting

## Installation

Add to your Gemfile:

```ruby
gem 'better_controller'
```

Then run:

```bash
bundle install
```

### Optional Dependencies

For full Turbo and ViewComponent support:

```ruby
gem 'turbo-rails', '>= 1.0'
gem 'view_component', '>= 3.0'
```

## Quick Start

### Basic Setup

Include `BetterController` in your controller:

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService
  end

  action :show do
    service Users::ShowService
  end

  action :create do
    service Users::CreateService

    on_success do
      html { redirect_to users_path }
      turbo_stream do
        prepend :users_list
        update :users_count
      end
    end

    on_error :validation do
      render_page status: :unprocessable_entity
    end
  end
end
```

### Service Integration

BetterController works seamlessly with service objects that return a result hash:

```ruby
class Users::IndexService
  def call
    users = User.all.order(created_at: :desc)

    {
      success: true,
      collection: users,
      page_config: {
        type: :index,
        title: 'Users',
        items: users
      }
    }
  end
end
```

## Action DSL

### Defining Actions

Use the `action` method to define controller actions:

```ruby
action :index do
  service Users::IndexService
end
```

### Service Configuration

Specify which service handles the action:

```ruby
action :show do
  service Users::ShowService

  # Optional: transform params before passing to service
  params_mapping do |params|
    { id: params[:id], include_posts: true }
  end
end
```

### Response Handlers

Define how to respond based on success or failure:

```ruby
action :create do
  service Users::CreateService

  on_success do
    html { redirect_to :index, notice: 'User created' }
    turbo_stream do
      prepend :users_list, partial: 'users/user'
      update :flash
    end
    json { render json: @result }
  end

  on_error :validation do
    html { render_page status: :unprocessable_entity }
    turbo_stream do
      replace :user_form
      update :form_errors
    end
    json { render json: @result, status: :unprocessable_entity }
  end

  on_error :not_found do
    html { redirect_to users_path, alert: 'User not found' }
  end
end
```

### Error Types

Built-in error classifications:

- `:validation` - ActiveRecord::RecordInvalid
- `:not_found` - ActiveRecord::RecordNotFound
- `:authorization` - Authorization failures
- `:any` - Catch-all for other errors

### Page and Component Rendering

Render ViewComponents directly:

```ruby
action :dashboard do
  component DashboardComponent
end

action :help do
  page HelpPage
end
```

## Action DSL Reference

Complete list of all available parameters in the `action` block:

### Service Configuration

| Parameter | Type | Description |
|-----------|------|-------------|
| `service(klass, method:)` | Class, Symbol | Service class to call. Default method: `:call` |
| `params_key(key)` | Symbol | Key for strong parameters (e.g., `:user`) |
| `permit(*attrs)` | Array | Permitted attributes for strong parameters |

```ruby
action :create do
  service Users::CreateService, method: :execute
  params_key :user
  permit :name, :email, :role, address: [:street, :city]
end
```

### Page and Component

| Parameter | Type | Description |
|-----------|------|-------------|
| `page(klass)` | Class | Page class that generates `page_config` via `#to_config` |
| `component(klass, locals:)` | Class, Hash | ViewComponent to render directly |
| `page_config(&block)` | Block | Modifier block for `page_config` from service |

```ruby
action :dashboard do
  service Users::DashboardService
  page Users::DashboardPage  # Fallback if service has no viewer
end

action :profile do
  component Users::ProfileComponent, locals: { show_avatar: true }
end

action :admin_index do
  service Users::IndexService
  page_config do |config|
    config[:title] = "Admin Users"
  end
end
```

### Turbo Support

| Parameter | Type | Description |
|-----------|------|-------------|
| `turbo_frame(frame_id)` | Symbol/String | Turbo Frame ID for this action |

```ruby
action :edit do
  service Users::EditService
  turbo_frame :user_form
end
```

### Response Handlers

| Parameter | Type | Description |
|-----------|------|-------------|
| `on_success(&block)` | Block | Handler for successful service result |
| `on_error(type, &block)` | Symbol, Block | Handler for specific error type |

Error types: `:validation`, `:not_found`, `:authorization`, `:any`

```ruby
action :create do
  service Users::CreateService

  on_success do
    html { redirect_to users_path, notice: 'Created!' }
    turbo_stream do
      prepend :users_list
      update :flash
    end
    json { render json: @result, status: :created }
  end

  on_error :validation do
    html { render_page status: :unprocessable_entity }
    turbo_stream { replace :user_form }
  end

  on_error :not_found do
    html { redirect_to users_path, alert: 'Not found' }
  end

  on_error :any do
    html { render_page status: :internal_server_error }
  end
end
```

### Callbacks

| Parameter | Type | Description |
|-----------|------|-------------|
| `before(&block)` | Block | Callback executed before the action |
| `after(&block)` | Block | Callback executed after the action (receives result) |

```ruby
action :update do
  before { @original_user = User.find(params[:id]).dup }
  service Users::UpdateService
  after { notify_changes(@original_user, @result[:resource]) }
end
```

### Authentication and Authorization

| Parameter | Type | Description |
|-----------|------|-------------|
| `skip_authentication(value)` | Boolean | Skip authentication for this action (default: true) |
| `skip_authorization(value)` | Boolean | Skip authorization for this action (default: true) |

```ruby
action :public_profile do
  skip_authentication
  skip_authorization
  service Users::PublicProfileService
end
```

## Turbo Support

### Turbo Stream Actions

Build Turbo Stream responses declaratively:

```ruby
on_success do
  turbo_stream do
    append :notifications, partial: 'shared/notification'
    prepend :items_list
    replace :item_counter
    update :flash
    remove :loading_spinner
  end
end
```

### Turbo Frame Detection

Check request context in your actions:

```ruby
def show
  if turbo_frame_request?
    render partial: 'user_card', locals: { user: @user }
  else
    render :show
  end
end
```

### Available Helpers

```ruby
turbo_frame_request?    # Is this a Turbo Frame request?
turbo_stream_request?   # Is this a Turbo Stream request?
current_turbo_frame     # Get the Turbo Frame ID
turbo_native_app?       # Is this from a Turbo Native app?
```

### Stream Helpers

Build individual streams:

```ruby
stream_append(:list, partial: 'item')
stream_prepend(:list, partial: 'item')
stream_replace(:item, partial: 'item')
stream_update(:counter, partial: 'counter')
stream_remove(:notification)
stream_before(:item, partial: 'new_item')
stream_after(:item, partial: 'new_item')
```

## ViewComponent Integration

### Page Config Rendering

When your service returns a `page_config`, BetterController automatically resolves and renders the appropriate component:

```ruby
# Service returns:
{
  success: true,
  page_config: {
    type: :index,
    title: 'Users',
    items: users
  }
}

# BetterController looks for:
# Templates::Index::PageComponent
```

### Component Rendering Helpers

Render components directly:

```ruby
render_component UserCardComponent, locals: { user: @user }
render_component_to_string AvatarComponent, locals: { user: @user }
render_component_collection users, UserRowComponent, item_key: :user
```

### Default Locals

Components automatically receive:

- `current_user` - If available
- `page_config` - The page configuration
- `result` - The service result
- `resource` - Single resource from result
- `collection` - Collection from result

## Configuration

Create an initializer:

```ruby
# config/initializers/better_controller.rb
BetterController.configure do |config|
  # ViewComponent namespace for page types
  config.page_component_namespace = 'Templates'

  # Pagination settings
  config.pagination = {
    enabled: true,
    per_page: 25
  }

  # Error handling
  config.error_handling = {
    log_errors: true,
    detailed_errors: Rails.env.development?
  }

  # Serialization
  config.serialization = {
    include_root: false,
    camelize_keys: true
  }
end
```

## Search/Filter Pattern

Handle initial page load and subsequent filter updates:

```ruby
action :index do
  service Users::IndexService

  on_success do
    html { render_page }

    turbo_stream do
      replace :users_table, partial: 'users/table'
      update :users_count
      update :active_filters
      update :pagination
    end
  end
end
```

The HTML request renders the full page, while Turbo Stream requests update only the changed elements.

## API Controllers

For JSON APIs, use `BetterControllerApi`:

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

### Response Format

Success response:

```json
{
  "success": true,
  "data": { "id": 1, "name": "John" }
}
```

Error response:

```json
{
  "success": false,
  "error": {
    "type": "ActiveRecord::RecordNotFound",
    "message": "Couldn't find User with id=999"
  }
}
```

## Utilities

### Parameter Validation

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::ParameterValidation

  requires_params :create, :name, :email

  param_schema :update, {
    name: { required: true, type: String },
    age: { type: Integer },
    role: { in: %w[admin user guest] }
  }
end
```

### Pagination

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::Pagination

  def index
    users = paginate(User.all)
    respond_with_pagination(users)
  end
end
```

### Logging

```ruby
class UsersController < ApplicationController
  include BetterController::Utils::Logging

  def create
    log_info('Creating user', user_email: params[:email])
    # ...
  rescue => e
    log_exception(e)
    raise
  end
end
```

## Testing

BetterController is fully tested with RSpec. Run the test suite:

```bash
bundle exec rspec
```

Current coverage: 75%+ with 444 examples.

## Requirements

- Ruby >= 3.0
- Rails >= 6.0
- Optional: turbo-rails >= 1.0
- Optional: view_component >= 3.0

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Ensure code style compliance (`bundle exec rubocop`)
6. Commit your changes (`git commit -am 'Add new feature'`)
7. Push to the branch (`git push origin feature/my-feature`)
8. Create a Pull Request

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

Alessio Bussolari - [alessio.bussolari@pandev.it](mailto:alessio.bussolari@pandev.it)

- GitHub: [@alessiobussolari](https://github.com/alessiobussolari)
- Repository: [https://github.com/alessiobussolari/better_controller](https://github.com/alessiobussolari/better_controller)
