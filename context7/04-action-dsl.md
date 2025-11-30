# Action DSL

Declarative action definition syntax.

---

## Basic Syntax

### Define an Action

```ruby
action :index do
  service Users::IndexService
end
```

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

Define page class for page_config:

```ruby
action :show do
  service Users::ShowService
  page Users::ShowPage
end
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
  params_key :user
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
  html { render_page }
  html { render_page status: :created }
end
```

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
  end

  on_error :authorization do
    html { redirect_to root_path, alert: 'Not authorized' }
  end

  on_error :any do
    html { redirect_to users_path }
  end
end
```

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

```ruby
@result      # Service result (unwrapped)
@error       # Exception if failed
@error_type  # :validation, :not_found, :authorization, :any
@page_config # Page configuration
```

--------------------------------

## Complete Example

### Full Action Definition

```ruby
class UsersController < ApplicationController
  include BetterController

  action :create do
    service Users::CreateService
    params_key :user
    permit :name, :email, :password

    before { authorize User }

    on_success do
      html { redirect_to users_path, notice: 'User created!' }
      turbo_stream do
        prepend :users_list, component: UserRowComponent
        flash type: :notice, message: 'Created!'
      end
      json { render json: @result[:resource], status: :created }
    end

    on_error :validation do
      html { render_page status: :unprocessable_entity }
      turbo_stream do
        replace :user_form, component: UserFormComponent
        form_errors errors: @result[:errors]
      end
    end
  end
end
```

--------------------------------
