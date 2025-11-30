# API Reference

Complete reference for all BetterController DSL methods.

--------------------------------

## Complete Action DSL Example

### Full DSL Block with All Options

Shows every available DSL method in a single action.

```ruby
class UsersController < ApplicationController
  include BetterController

  action :create do
    # Service configuration
    service Users::CreateService, method: :call

    # ViewComponent configuration
    page Users::CreatePage
    component Users::FormComponent, locals: { mode: :create }

    # Page config customization
    page_config do |config|
      config.title = "Create User"
      config.breadcrumbs = [{ label: "Users", path: "/users" }]
    end

    # Parameter configuration
    params_key :user
    permit :name, :email, :password, :department_id, roles: []

    # Lifecycle callbacks
    before do
      @departments = Department.active
      authorize User
    end

    after do |result|
      AuditLog.record(action: :user_created, resource: result[:resource])
    end

    # Authentication/Authorization skipping
    skip_authentication
    skip_authorization

    # Success handler
    on_success do
      html { redirect_to users_path, notice: 'User created!' }

      turbo_stream do
        prepend :users_list, partial: 'users/row', locals: { user: @result[:resource] }
        update :users_count, partial: 'users/count', locals: { count: User.count }
        flash type: :notice, message: 'User created!'
        remove :new_user_modal
      end

      json { respond_with_success(serialize_user(@result[:resource]), status: :created) }

      csv do
        send_csv [@result[:resource]], filename: 'new_user.csv', columns: [:id, :name, :email]
      end

      xml { render xml: @result[:resource], status: :created }
    end

    # Error handlers
    on_error :validation do
      html { render :new, status: :unprocessable_entity }
      turbo_stream do
        replace :user_form, partial: 'users/form', locals: { user: @result[:resource] }
        form_errors errors: @result[:errors]
      end
      json { respond_with_error(@result[:errors]) }
    end

    on_error :not_found do
      html { redirect_to users_path, alert: 'User not found' }
      json { respond_with_error('User not found', status: :not_found) }
    end

    on_error :unauthorized do
      html { redirect_to root_path, alert: 'Not authorized' }
      json { respond_with_error('Unauthorized', status: :unauthorized) }
    end

    on_error :forbidden do
      html { redirect_to root_path, alert: 'Access denied' }
      json { respond_with_error('Forbidden', status: :forbidden) }
    end
  end
end
```

--------------------------------

## ActionBuilder Methods

### service

Define service class to execute.

```ruby
action :create do
  service Users::CreateService
  service Users::CreateService, method: :perform
end
```

--------------------------------

### page

Define ViewComponent page class.

```ruby
action :show do
  page Users::ShowPage
end
```

--------------------------------

### component

Define ViewComponent with locals.

```ruby
action :new do
  component Users::FormComponent, locals: { mode: :create }
end
```

--------------------------------

### page_config

Customize page configuration.

```ruby
action :index do
  page_config do |config|
    config.title = "All Users"
    config.per_page = 25
  end
end
```

--------------------------------

### params_key

Set root key for permitted parameters.

```ruby
action :create do
  params_key :user
  permit :name, :email
end
```

--------------------------------

### permit

Define permitted parameters.

```ruby
action :update do
  params_key :user
  permit :name, :email, :bio, settings: [:theme, :notifications]
  permit :name, role_ids: [], tags: []
  permit :name, address_attributes: [:street, :city, :zip]
end
```

--------------------------------

### on_success

Define success response handler.

```ruby
action :index do
  on_success do
    html { render :index }
    json { respond_with_success(@collection) }
  end
end
```

--------------------------------

### on_error

Define error response handlers by type.

```ruby
action :show do
  on_error :not_found do
    html { redirect_to users_path, alert: 'Not found' }
    json { respond_with_error('Not found', status: :not_found) }
  end

  on_error :validation do
    html { render :edit, status: :unprocessable_entity }
  end
end
```

Supported types: `:validation`, `:not_found`, `:unauthorized`, `:forbidden`, `:unprocessable_entity`, `:server_error`

--------------------------------

### before

Define callback that runs before action.

```ruby
action :show do
  before do
    @user = User.find(params[:id])
    authorize @user
  end
end
```

--------------------------------

### after

Define callback that runs after action.

```ruby
action :create do
  after do |result|
    NotificationMailer.welcome(result[:resource]).deliver_later if result[:success]
  end
end
```

--------------------------------

### skip_authentication

Skip authentication for this action.

```ruby
action :index do
  skip_authentication
end
```

--------------------------------

### skip_authorization

Skip authorization for this action.

```ruby
action :new do
  skip_authorization
end
```

--------------------------------

## ResponseBuilder Methods

### html

Handle HTML format requests.

```ruby
on_success do
  html do
    @users = @result[:collection]
    render :index
  end
end
```

--------------------------------

### turbo_stream

Handle Turbo Stream requests.

```ruby
on_success do
  turbo_stream do
    prepend :list, partial: 'item', locals: { item: @result[:resource] }
    flash type: :notice, message: 'Created!'
  end
end
```

--------------------------------

### json

Handle JSON format requests.

```ruby
on_success do
  json do
    respond_with_success(serialize(@result[:resource]))
  end
end
```

--------------------------------

### csv

Handle CSV format requests.

```ruby
on_success do
  csv do
    send_csv @result[:collection],
      filename: "export_#{Date.current}.csv",
      columns: [:id, :name, :email],
      headers: { id: 'ID', name: 'Full Name', email: 'Email Address' }
  end
end
```

--------------------------------

### xml

Handle XML format requests.

```ruby
on_success do
  xml do
    render xml: @result[:resource]
  end
end
```

--------------------------------

### redirect_to

Redirect to path with optional flash.

```ruby
on_success do
  html { redirect_to users_path, notice: 'User saved!' }
end
```

--------------------------------

### render_page

Render configured page component.

```ruby
action :show do
  page Users::ShowPage

  on_success do
    html { render_page }
    html { render_page(status: :ok) }
  end
end
```

--------------------------------

### render_component

Render specific ViewComponent.

```ruby
on_success do
  html do
    render_component Users::CardComponent, locals: { user: @result[:resource] }
  end
end
```

--------------------------------

### render_partial

Render partial template.

```ruby
on_success do
  html do
    render_partial 'users/details', locals: { user: @result[:resource] }
  end
end
```

--------------------------------

## TurboStreamBuilder Methods

### append

Append content to target element.

```ruby
turbo_stream do
  append :users_list, partial: 'users/row', locals: { user: @user }
  append :notifications, component: NotificationComponent.new(message: 'Added!')
end
```

--------------------------------

### prepend

Prepend content to target element.

```ruby
turbo_stream do
  prepend :messages, partial: 'messages/message', locals: { message: @message }
end
```

--------------------------------

### replace

Replace target element entirely.

```ruby
turbo_stream do
  replace :user_card, partial: 'users/card', locals: { user: @user }
  replace @user, partial: 'users/row'  # Uses dom_id(@user) as target
end
```

--------------------------------

### update

Update inner content of target element.

```ruby
turbo_stream do
  update :user_details, partial: 'users/details', locals: { user: @user }
end
```

--------------------------------

### remove

Remove target element from DOM.

```ruby
turbo_stream do
  remove :modal
  remove @user  # Uses dom_id(@user) as target
end
```

--------------------------------

### before

Insert content before target element.

```ruby
turbo_stream do
  before :first_item, partial: 'items/item', locals: { item: @item }
end
```

--------------------------------

### after

Insert content after target element.

```ruby
turbo_stream do
  after :header, partial: 'shared/announcement'
end
```

--------------------------------

### flash

Update flash messages via Turbo Stream.

```ruby
turbo_stream do
  flash type: :notice, message: 'Operation successful!'
  flash type: :alert, message: 'Please check the form'
end
```

--------------------------------

### form_errors

Update form errors display.

```ruby
turbo_stream do
  form_errors errors: @result[:errors]
  form_errors errors: @user.errors, target: :user_form_errors
end
```

--------------------------------

### refresh

Trigger full page refresh (Turbo 8+).

```ruby
turbo_stream do
  refresh
end
```

--------------------------------

## Instance Variables

### @result

Hash returned by service.

```ruby
@result[:success]    # Boolean
@result[:resource]   # Single resource
@result[:collection] # Collection of resources
@result[:errors]     # Validation errors
@result[:meta]       # Additional metadata
```

--------------------------------

## Response Helpers

### respond_with_success

Return successful JSON response.

```ruby
respond_with_success({ id: 1, name: 'John' })
respond_with_success(users, meta: { total: 100 }, status: :created)
```

Response format:
```json
{
  "data": { "id": 1, "name": "John" },
  "meta": { "version": "v1", "total": 100 }
}
```

--------------------------------

### respond_with_error

Return error JSON response.

```ruby
respond_with_error('Something went wrong')
respond_with_error(user.errors)
respond_with_error({ email: ['is invalid'] }, status: :bad_request)
```

Response format:
```json
{
  "data": {
    "error": {
      "messages": ["Email is invalid"],
      "details": { "email": ["is invalid"] }
    }
  },
  "meta": { "version": "v1" }
}
```

--------------------------------

## CSV Export

### send_csv

Send CSV file as download.

```ruby
send_csv @users,
  filename: "users_#{Date.current}.csv",
  columns: [:id, :name, :email, :created_at],
  headers: {
    id: 'User ID',
    name: 'Full Name',
    email: 'Email Address',
    created_at: 'Registration Date'
  }
```

--------------------------------

### generate_csv

Generate CSV content as string.

```ruby
csv_content = generate_csv(@users, columns: [:id, :name], headers: { id: 'ID', name: 'Name' })
```

--------------------------------

## Pagination

### configure_pagination

Set default pagination options.

```ruby
class UsersController < ApplicationController
  include BetterController
  include BetterController::Utils::Pagination

  configure_pagination per_page: 50
end
```

--------------------------------

### paginate

Paginate collection based on request parameters.

```ruby
@users = paginate(User.all)
# Respects params[:page] and params[:per_page]
```

--------------------------------

### pagination_meta

Generate pagination metadata for JSON.

```ruby
respond_with_success(
  users.map { |u| serialize(u) },
  meta: pagination_meta(users)
)
```

Returns: `{ current_page: 1, total_pages: 10, total_count: 250, per_page: 25 }`

--------------------------------

## Parameter Helpers

### boolean_param

Parse parameter as boolean.

```ruby
boolean_param(:active)           # "true" -> true, "1" -> true
boolean_param(:featured, default: true)
```

--------------------------------

### integer_param

Parse parameter as integer.

```ruby
integer_param(:page)             # "5" -> 5
integer_param(:limit, default: 10)
```

--------------------------------

### array_param

Parse parameter as array.

```ruby
array_param(:ids)                # "1,2,3" -> [1, 2, 3]
array_param(:tags)               # ["a", "b"] -> ["a", "b"]
```

--------------------------------

### date_param

Parse parameter as date.

```ruby
date_param(:start_date)          # "2024-01-15" -> Date object
date_param(:end_date, default: Date.current)
```

--------------------------------

### datetime_param

Parse parameter as datetime.

```ruby
datetime_param(:scheduled_at)    # ISO8601 string -> DateTime object
```
