# Action DSL Reference

The Action DSL provides a declarative way to define controller actions with services, pages, components, and response handlers.

## Defining Actions

Use the `action` method to define controller actions:

```ruby
action :index do
  service Users::IndexService
end
```

## Service Configuration

### service(klass, method:)

Specify which service handles the action:

```ruby
action :show do
  service Users::ShowService                    # Uses :call method
  service Users::ShowService, method: :execute  # Custom method
end
```

### params_key(key)

Define the root key for strong parameters:

```ruby
action :create do
  service Users::CreateService
  params_key :user  # Uses params[:user]
end
```

### permit(*attrs)

Define permitted attributes for strong parameters:

```ruby
action :create do
  service Users::CreateService
  params_key :user
  permit :name, :email, :role, address: [:street, :city, :zip]
end
```

## Page and Component

### page(klass)

Define a page class that generates `page_config`:

```ruby
action :dashboard do
  service Users::DashboardService
  page Users::DashboardPage  # Fallback if service has no viewer
end
```

The page class should respond to `#to_config`:

```ruby
class Users::DashboardPage
  def initialize(data:, user:, params:)
    @data = data
    @user = user
    @params = params
  end

  def to_config
    {
      type: :dashboard,
      title: 'Dashboard',
      widgets: build_widgets
    }
  end
end
```

### component(klass, locals:)

Render a ViewComponent directly without page_config:

```ruby
action :profile do
  component Users::ProfileComponent
  component Users::ProfileComponent, locals: { show_avatar: true }
end
```

### page_config(&block)

Modify page_config from service:

```ruby
action :admin_index do
  service Users::IndexService

  page_config do |config|
    config[:title] = "Admin Users"
    config[:show_delete] = true
  end
end
```

## Turbo Support

### turbo_frame(frame_id)

Specify the Turbo Frame ID for this action:

```ruby
action :edit do
  service Users::EditService
  turbo_frame :user_form
end
```

## Response Handlers

### on_success(&block)

Define how to respond on success:

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
end
```

### on_error(type, &block)

Define handlers for specific error types:

```ruby
action :create do
  service Users::CreateService

  on_error :validation do
    html { render_page status: :unprocessable_entity }
    turbo_stream { replace :user_form }
  end

  on_error :not_found do
    html { redirect_to users_path, alert: 'Not found' }
  end

  on_error :authorization do
    html { redirect_to root_path, alert: 'Access denied' }
  end

  on_error :any do
    html { render_page status: :internal_server_error }
  end
end
```

**Error types:**
- `:validation` - ActiveRecord::RecordInvalid, ActiveModel::ValidationError
- `:not_found` - ActiveRecord::RecordNotFound
- `:authorization` - Pundit::NotAuthorizedError, CanCan::AccessDenied
- `:any` - Catch-all for other errors

## Callbacks

### before(&block)

Execute code before the action:

```ruby
action :update do
  before { @original = User.find(params[:id]).dup }
  service Users::UpdateService
end
```

### after(&block)

Execute code after the action (receives result):

```ruby
action :create do
  service Users::CreateService
  after { notify_admin(@result[:resource]) }
end
```

## Authentication and Authorization

### skip_authentication(value)

Skip authentication for this action:

```ruby
action :public_profile do
  skip_authentication
  service Users::PublicProfileService
end
```

### skip_authorization(value)

Skip authorization for this action:

```ruby
action :public_list do
  skip_authentication
  skip_authorization
  service Users::PublicListService
end
```

## Complete Example

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService
    turbo_frame :users_content

    on_success do
      html { render_page }
      turbo_stream do
        replace :users_table
        update :users_count
      end
    end
  end

  action :create do
    service Users::CreateService
    params_key :user
    permit :name, :email, :role

    before { authorize User }

    on_success do
      html { redirect_to users_path, notice: 'User created!' }
      turbo_stream do
        prepend :users_list
        update :flash
      end
    end

    on_error :validation do
      html { render_page status: :unprocessable_entity }
      turbo_stream do
        replace :user_form
        update :form_errors
      end
    end
  end

  action :destroy do
    service Users::DestroyService

    on_success do
      html { redirect_to users_path }
      turbo_stream { remove @result[:resource] }
    end
  end
end
```
