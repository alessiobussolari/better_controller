# Action DSL

The Action DSL provides a declarative way to define controller actions with services, pages, components, and response handlers.

---

## Overview

Instead of writing imperative controller code, you define actions declaratively:

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService
    on_success { html { render_page } }
  end
end
```

## Basic Syntax

```ruby
action :action_name do
  # Configuration goes here
end
```

This automatically defines the instance method `action_name` on your controller.

## Service Configuration

### service

Call a service class:

```ruby
action :create do
  service Users::CreateService
end

# With custom method
action :create do
  service Users::CreateService, method: :perform
end
```

Services can follow multiple patterns:

```ruby
# Class method style
class Users::CreateService
  def self.call(params:, id: nil)
    # ...
  end
end

# Instance method style (receives current_user if available)
class Users::CreateService
  def initialize(user, params:)
    @user = user
    @params = params
  end

  def call
    # ...
  end
end
```

## Page and Component Configuration

### page

Define a Page class for UI configuration. The page receives data from the service result and generates page configuration.

```ruby
action :show do
  service Users::ShowService  # → data (Hash or Result)
  page Users::ShowPage        # → page config (Hash or Config object)
end
```

The page class is instantiated with service result data and current_user:

```ruby
# Signature: Page.new(data, user: current_user).action_name
```

#### Page Return Types

Pages can return different types, all automatically normalized:

**1. Return Hash (simplest - automatically wrapped)**

```ruby
class Users::IndexPage
  def initialize(data, user: nil)
    @data = data
    @user = user
  end

  def index
    { header: { title: 'Users' }, table: { items: @data } }
  end
end
# Result: Hash is wrapped in BetterController::Config
```

**2. Return BetterController::Config (standalone with meta)**

```ruby
class Users::ShowPage
  def initialize(data, user: nil)
    @data = data
  end

  def show
    BetterController::Config.new(
      { header: { title: @data.name }, details: { resource: @data } },
      meta: { page_type: :show, editable: @data.editable? }
    )
  end
end
# Result: BetterController::Config returned as-is
```

**3. Return BetterPage::Config (with BetterPage gem)**

```ruby
class Users::ShowPage < BetterPage::Base
  def initialize(data, user: nil)
    @data = data
    @user = user
  end

  def show
    BetterPage::Config.new(
      { header: { title: @data.name }, details: { resource: @data } },
      meta: { page_type: :show }
    )
  end
end
# Result: BetterPage::Config returned as-is (requires page_config_class configuration)
```

#### Normalization Behavior

| Page Returns | @page_config Result |
|--------------|---------------------|
| `Hash` | `BetterController::Config.new(hash)` |
| `BetterController::Config` | Returned as-is |
| `BetterPage::Config` (if configured) | Returned as-is |
| `nil` | `nil` |

**Note:** Services handle business logic and return data. Pages handle UI configuration. These are separate concerns.

### component

Render a ViewComponent directly:

```ruby
action :index do
  component Users::ListComponent
end

# With locals
action :index do
  component Users::ListComponent, locals: { title: 'All Users' }
end
```

## Parameter Configuration

### params_key

Set the root key for strong parameters:

```ruby
action :create do
  service Users::CreateService
  params_key :user  # Uses params[:user]
end
```

### permit

Define permitted parameters:

```ruby
action :create do
  service Users::CreateService
  params_key :user
  permit :name, :email, :password
end

# Nested parameters
action :create do
  permit :name, :email, address: [:street, :city, :zip]
end
```

## Callbacks

### before

Execute code before the service:

```ruby
action :update do
  before { authorize @resource }
  service Users::UpdateService
end
```

### after

Execute code after the service:

```ruby
action :create do
  service Users::CreateService
  after { |result| track_event('user_created', result) }
end
```

## Success Handlers

### on_success

Define response handlers for successful actions:

```ruby
action :create do
  service Users::CreateService

  on_success do
    html { redirect_to users_path }
    turbo_stream { prepend :users_list, component: UserRowComponent }
    json { render json: @result }
  end
end
```

### Format Handlers

Inside `on_success`, you can define format-specific handlers:

```ruby
on_success do
  html { redirect_to users_path, notice: 'Created!' }
  turbo_stream do
    append :users, partial: 'users/user'
    update :flash, partial: 'shared/flash'
  end
  json { render json: build_json_response(@result) }
  csv { send_csv @result[:collection] }
  xml { render xml: @result[:resource] }
end
```

### HTML Response Helpers

```ruby
on_success do
  html { redirect_to users_path }
  html { render_page }  # Uses page config from Page class
  html { render_page status: :created }
  html { render_component UserComponent, locals: { user: @result[:resource] } }
end
```

**Note:** For Turbo Frame requests, if `@page_config` has a `klass` attribute (ViewComponent class), BetterController automatically renders the component with `layout: false`. For normal HTML requests, it uses Rails standard render (looks for .html.erb view).

## Error Handlers

### on_error

Handle specific error types:

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

### Error Types

| Type | Matches |
|------|---------|
| `:validation` | `ActiveRecord::RecordInvalid`, `ActiveModel::ValidationError` |
| `:not_found` | `ActiveRecord::RecordNotFound` |
| `:authorization` | `Pundit::NotAuthorizedError`, `CanCan::AccessDenied` |
| `:any` | Any other error (catch-all) |

## Turbo Stream Builder

Build multiple streams in the turbo_stream handler:

```ruby
on_success do
  turbo_stream do
    append :users_list, component: UserRowComponent
    update :count, partial: 'users/count'
    remove :empty_state
    flash type: :notice, message: 'User created!'
  end
end

on_error :validation do
  turbo_stream do
    replace :user_form, component: UserFormComponent
    form_errors errors: @result[:errors]
    flash type: :alert, message: 'Please fix errors'
  end
end
```

### Available Stream Actions

| Action | Description |
|--------|-------------|
| `append(target, ...)` | Append content to target |
| `prepend(target, ...)` | Prepend content to target |
| `replace(target, ...)` | Replace target element |
| `update(target, ...)` | Update target's inner HTML |
| `remove(target)` | Remove target element |
| `before(target, ...)` | Insert before target |
| `after(target, ...)` | Insert after target |
| `flash(type:, message:)` | Update flash message |
| `form_errors(errors:, target:)` | Update form errors |
| `refresh` | Refresh the page (Turbo 8+) |

## Authentication/Authorization Skip

```ruby
action :index do
  skip_authentication
  skip_authorization
  service Users::IndexService
end
```

## Instance Variables

After action execution, these instance variables are available:

| Variable | Description |
|----------|-------------|
| `@result` | Service result (unwrapped if using wrapped responses) |
| `@error` | Exception if service failed |
| `@error_type` | Classified error type (`:validation`, `:not_found`, etc.) |
| `@page_config` | Page configuration for rendering (`BetterController::Config` or `BetterPage::Config`) |

## Complete Example

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService

    on_success do
      html { render_page }
      turbo_stream { replace :users_list, component: UsersListComponent }
      json { render json: @result }
      csv { send_csv @result[:collection], filename: 'users.csv' }
    end
  end

  action :create do
    service Users::CreateService
    params_key :user
    permit :name, :email, :password, :role

    before { authorize User }

    on_success do
      html { redirect_to users_path, notice: 'User created!' }
      turbo_stream do
        prepend :users_list, component: UserRowComponent
        update :users_count, partial: 'users/count'
        flash type: :notice, message: 'User created successfully!'
      end
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
  end

  action :destroy do
    service Users::DestroyService

    on_success do
      html { redirect_to users_path, notice: 'User deleted' }
      turbo_stream do
        remove @result[:resource]
        update :users_count, partial: 'users/count'
      end
    end
  end
end
```
