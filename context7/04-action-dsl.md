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

### Define an Action

```ruby
action :action_name do
  # Configuration goes here
end
```

This automatically defines the instance method `action_name` on your controller.

--------------------------------

## Service Configuration

### service

Call a service class:

```ruby
action :create do
  service Users::CreateService
end
```

--------------------------------

### service with method

Specify custom method:

```ruby
action :create do
  service Users::CreateService, method: :perform
end
```

--------------------------------

## Page and Component

### page

Define Page class for UI configuration:

```ruby
action :show do
  service Users::ShowService  # → data (Hash or Result)
  page Users::ShowPage        # → page config (Hash or Config object)
end
```

The page class receives data and current_user:

```ruby
# Signature: Page.new(data, user: current_user).action_name
```

--------------------------------

### component

Render ViewComponent directly:

```ruby
action :index do
  component Users::ListComponent
end

action :index do
  component Users::ListComponent, locals: { title: 'Users' }
end
```

--------------------------------

## Parameters

### params_key

Set root key for strong parameters:

```ruby
action :create do
  params_key :user  # Uses params[:user]
  service Users::CreateService
end
```

--------------------------------

### permit

Define permitted parameters:

```ruby
action :create do
  params_key :user
  permit :name, :email, :password
  service Users::CreateService
end

# Nested parameters
action :create do
  permit :name, :email, address: [:street, :city, :zip]
end
```

--------------------------------

## Callbacks

### before

Execute before service:

```ruby
action :update do
  before { authorize @resource }
  service Users::UpdateService
end
```

--------------------------------

### after

Execute after service:

```ruby
action :create do
  service Users::CreateService
  after { |result| track_event('user_created') }
end
```

--------------------------------

## Success Handlers

### on_success with format handlers

```ruby
action :create do
  service Users::CreateService

  on_success do
    html { redirect_to users_path }
    turbo_stream { prepend :users_list, component: UserRowComponent }
    json { render json: @result }
    csv { send_csv @result[:collection] }
  end
end
```

--------------------------------

### redirect_to

```ruby
on_success do
  html { redirect_to users_path, notice: 'Created!' }
end
```

--------------------------------

### render_page

```ruby
on_success do
  html { render_page }  # Uses page config from Page class
  html { render_page status: :created }
end
```

**Note:** For Turbo Frame requests, if `@page_config` has a `klass` attribute (ViewComponent class), BetterController automatically renders the component with `layout: false`. For normal HTML requests, it uses Rails standard render (looks for .html.erb view).

--------------------------------

### render_component

```ruby
on_success do
  html { render_component UserComponent, locals: { user: @result[:resource] } }
end
```

--------------------------------

## Error Handlers

### on_error with type

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

--------------------------------

## Turbo Stream Builder

### Stream actions in on_success

```ruby
on_success do
  turbo_stream do
    append :users_list, component: UserRowComponent
    prepend :notifications, partial: 'notification'
    replace :user_1, partial: 'users/user'
    update :counter, html: '<span>42</span>'
    remove :empty_state
    flash type: :notice, message: 'Success!'
    form_errors errors: @result[:errors]
    refresh  # Turbo 8+
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

--------------------------------

## Authentication/Authorization Skip

### skip_authentication, skip_authorization

```ruby
action :index do
  skip_authentication
  skip_authorization
  service Users::IndexService
end
```

--------------------------------

## Instance Variables

### Available after execution

| Variable | Description |
|----------|-------------|
| `@result` | Service result (unwrapped if using wrapped responses) |
| `@error` | Exception if service failed |
| `@error_type` | Classified error type (`:validation`, `:not_found`, etc.) |
| `@page_config` | Page configuration (`BetterController::Config` or `BetterPage::Config`) |

--------------------------------

## Complete Example

### Full Action Definition

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

--------------------------------
