# API Reference

Complete reference for all BetterController DSL methods and options.

---

## Complete Action DSL Example

This example shows ALL available options in a single action block:

```ruby
class UsersController < ApplicationController
  include BetterController

  action :create do
    # Service configuration
    service Users::CreateService, method: :call

    # ViewComponent configuration (Page handles UI config, Component for direct rendering)
    page Users::CreatePage
    component Users::FormComponent, locals: { mode: :create }

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
      html do
        redirect_to users_path, notice: 'User created successfully!'
      end

      turbo_stream do
        prepend :users_list, partial: 'users/row', locals: { user: @result[:resource] }
        update :users_count, partial: 'users/count', locals: { count: User.count }
        flash type: :notice, message: 'User created!'
        remove :new_user_modal
      end

      json do
        respond_with_success(serialize_user(@result[:resource]), status: :created)
      end

      csv do
        send_csv [@result[:resource]], filename: 'new_user.csv', columns: [:id, :name, :email]
      end

      xml do
        render xml: @result[:resource], status: :created
      end
    end

    # Error handlers
    on_error :validation do
      html do
        @user = @result[:resource]
        render :new, status: :unprocessable_entity
      end

      turbo_stream do
        replace :user_form, partial: 'users/form', locals: { user: @result[:resource] }
        form_errors errors: @result[:errors], target: :form_errors
      end

      json do
        respond_with_error(@result[:errors])
      end
    end

    on_error :not_found do
      html { redirect_to users_path, alert: 'User not found' }
      json { respond_with_error('User not found', status: :not_found) }
    end

    on_error :authorization do
      html { redirect_to root_path, alert: 'Not authorized' }
      json { respond_with_error('Not authorized', status: :forbidden) }
    end

    on_error :any do
      html { redirect_to root_path, alert: 'An error occurred' }
      json { respond_with_error('An error occurred', status: :internal_server_error) }
    end
  end
end
```

---

## ActionBuilder Methods

Methods available inside `action :name do ... end` blocks.

### service(klass, method: :call)

Define the service class to execute for this action.

```ruby
action :create do
  service Users::CreateService
  service Users::CreateService, method: :perform
end
```

**Parameters:**
- `klass` - The service class (must respond to the specified method)
- `method:` - The method to call on the service (default: `:call`)

**Service Contract:**
Your service should return a hash with:
- `success:` - Boolean indicating success/failure
- `resource:` - Single resource (for show/create/update/destroy)
- `collection:` - Collection of resources (for index)
- `errors:` - Validation errors (when success is false)

### page(klass)

Define a Page class for UI configuration. The page receives data from the service result.

```ruby
action :show do
  service Users::ShowService  # → data (Hash or Result)
  page Users::ShowPage        # → page config (Hash or Config object)
end
```

**Page Contract:**
The page class is instantiated with the signature `Page.new(data, user: current_user)`:

**Valid Return Types:**

| Return Type | Result |
|-------------|--------|
| `Hash` | Wrapped in `BetterController::Config` |
| `BetterController::Config` | Returned as-is |
| `BetterPage::Config` (if configured) | Returned as-is |

**Example 1: Return Hash (simplest)**

```ruby
class Users::ShowPage
  def initialize(data, user: nil)
    @data = data
    @user = user
  end

  def show
    { header: { title: @data.name }, details: { resource: @data } }
  end
end
```

**Example 2: Return BetterController::Config (with meta)**

```ruby
class Users::ShowPage
  def initialize(data, user: nil)
    @data = data
  end

  def show
    BetterController::Config.new(
      { header: { title: @data.name } },
      meta: { page_type: :show, editable: true }
    )
  end
end
```

**Example 3: Return BetterPage::Config (with BetterPage gem)**

```ruby
class Users::ShowPage < BetterPage::Base
  def initialize(data, user: nil)
    @data = data
    @user = user
  end

  def show
    BetterPage::Config.new(
      { header: { title: @data.name } },
      meta: { page_type: :show }
    )
  end
end
```

**Note:** Services return data, Pages return UI configuration. These are separate concerns.

### component(klass, locals: {})

Define a ViewComponent to render directly (without using BetterPage).

```ruby
action :new do
  component Users::FormComponent, locals: { mode: :create }
end
```

### params_key(key)

Set the root key for permitted parameters.

```ruby
action :create do
  params_key :user
  permit :name, :email
end
```

### permit(*attrs)

Define permitted parameters.

```ruby
action :update do
  params_key :user
  permit :name, :email, :bio, settings: [:theme, :notifications]
end
```

**Nested attributes:**
```ruby
permit :name, address_attributes: [:street, :city, :zip]
```

**Array attributes:**
```ruby
permit :name, role_ids: [], tags: []
```

### on_success(&block)

Define the success response handler.

```ruby
action :index do
  on_success do
    html { render :index }
    json { respond_with_success(@collection) }
  end
end
```

### on_error(type, &block)

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

**Supported error types:**
- `:validation` - Validation errors (ActiveRecord::RecordInvalid, ActiveModel::ValidationError)
- `:not_found` - Resource not found (ActiveRecord::RecordNotFound)
- `:authorization` - Authorization denied (Pundit::NotAuthorizedError, CanCan::AccessDenied)
- `:any` - Catch-all for any other error

### before(&block)

Define a callback that runs before the action.

```ruby
action :show do
  before do
    @user = User.find(params[:id])
    authorize @user
  end
end
```

### after(&block)

Define a callback that runs after the action.

```ruby
action :create do
  after do |result|
    NotificationMailer.welcome(result[:resource]).deliver_later if result[:success]
  end
end
```

### skip_authentication

Skip authentication for this action.

```ruby
action :index do
  skip_authentication
end
```

### skip_authorization

Skip authorization for this action.

```ruby
action :new do
  skip_authorization
end
```

---

## ResponseBuilder Methods

Methods available inside `on_success` and `on_error` blocks.

### html(&block)

Handle HTML format requests.

```ruby
on_success do
  html do
    @users = @result[:collection]
    render :index
  end
end
```

### turbo_stream(&block)

Handle Turbo Stream requests.

```ruby
on_success do
  turbo_stream do
    prepend :list, partial: 'item', locals: { item: @result[:resource] }
    flash type: :notice, message: 'Created!'
  end
end
```

### json(&block)

Handle JSON format requests.

```ruby
on_success do
  json do
    respond_with_success(serialize(@result[:resource]))
  end
end
```

### csv(&block)

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

### xml(&block)

Handle XML format requests.

```ruby
on_success do
  xml do
    render xml: @result[:resource]
  end
end
```

### redirect_to(path, **options)

Redirect to a path with optional flash message.

```ruby
on_success do
  html do
    redirect_to users_path, notice: 'User saved!'
  end
end
```

### render_page(status: :ok)

Render the configured page component.

```ruby
action :show do
  page Users::ShowPage

  on_success do
    html { render_page }
    # With custom status
    html { render_page(status: :ok) }
  end
end
```

### render_component(klass, locals: {}, status: :ok)

Render a specific ViewComponent.

```ruby
on_success do
  html do
    render_component Users::CardComponent, locals: { user: @result[:resource] }
  end
end
```

### render_partial(path, locals: {}, status: :ok)

Render a partial template.

```ruby
on_success do
  html do
    render_partial 'users/details', locals: { user: @result[:resource] }
  end
end
```

---

## TurboStreamBuilder Methods

Methods available inside `turbo_stream` blocks.

### append(target, component: nil, partial: nil, locals: {})

Append content to a target element.

```ruby
turbo_stream do
  append :users_list, partial: 'users/row', locals: { user: @user }
  append :notifications, component: NotificationComponent.new(message: 'Added!')
end
```

### prepend(target, component: nil, partial: nil, locals: {})

Prepend content to a target element.

```ruby
turbo_stream do
  prepend :messages, partial: 'messages/message', locals: { message: @message }
end
```

### replace(target, component: nil, partial: nil, locals: {})

Replace a target element entirely.

```ruby
turbo_stream do
  replace :user_card, partial: 'users/card', locals: { user: @user }
  replace @user, partial: 'users/row'  # Uses dom_id(@user) as target
end
```

### update(target, component: nil, partial: nil, locals: {})

Update the inner content of a target element.

```ruby
turbo_stream do
  update :user_details, partial: 'users/details', locals: { user: @user }
end
```

### remove(target)

Remove a target element from the DOM.

```ruby
turbo_stream do
  remove :modal
  remove @user  # Uses dom_id(@user) as target
end
```

### before(target, component: nil, partial: nil, locals: {})

Insert content before a target element.

```ruby
turbo_stream do
  before :first_item, partial: 'items/item', locals: { item: @item }
end
```

### after(target, component: nil, partial: nil, locals: {})

Insert content after a target element.

```ruby
turbo_stream do
  after :header, partial: 'shared/announcement'
end
```

### flash(type:, message:)

Update flash messages via Turbo Stream.

```ruby
turbo_stream do
  flash type: :notice, message: 'Operation successful!'
  flash type: :alert, message: 'Please check the form'
end
```

### form_errors(errors:, target: :form_errors)

Update form errors display.

```ruby
turbo_stream do
  form_errors errors: @result[:errors]
  form_errors errors: @user.errors, target: :user_form_errors
end
```

### refresh

Trigger a full page refresh (Turbo 8+).

```ruby
turbo_stream do
  refresh
end
```

---

## Instance Variables

Variables available in response blocks after action execution.

### @result

The hash returned by the service (if configured).

```ruby
@result[:success]    # Boolean
@result[:resource]   # Single resource
@result[:collection] # Collection of resources
@result[:errors]     # Validation errors
@result[:meta]       # Additional metadata
```

### @resource

Alias for `@result[:resource]` (single resource).

### @collection

Alias for `@result[:collection]` (collection of resources).

### @errors

Alias for `@result[:errors]` (validation errors).

---

## Response Helpers

Methods available in all controllers that include BetterController.

### respond_with_success(data, meta: {}, status: :ok)

Return a successful JSON response.

```ruby
respond_with_success({ id: 1, name: 'John' })
respond_with_success(users, meta: { total: 100 }, status: :created)
```

**Response format:**
```json
{
  "data": { "id": 1, "name": "John" },
  "meta": { "version": "v1", "total": 100 }
}
```

### respond_with_error(errors, status: :unprocessable_entity)

Return an error JSON response.

```ruby
respond_with_error('Something went wrong')
respond_with_error(user.errors)
respond_with_error({ email: ['is invalid'] }, status: :bad_request)
```

**Response format:**
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

---

## CSV Export

Methods for CSV generation and export.

### send_csv(collection, filename:, columns:, headers: {})

Send a CSV file as a download.

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

**Parameters:**
- `collection` - Array of objects to export
- `filename:` - Name of the downloaded file
- `columns:` - Array of attribute names to include
- `headers:` - Hash mapping column names to header labels

### generate_csv(collection, columns:, headers: {})

Generate CSV content as a string.

```ruby
csv_content = generate_csv(@users, columns: [:id, :name], headers: { id: 'ID', name: 'Name' })
```

---

## Pagination

Methods available when including `BetterController::Utils::Pagination`.

### configure_pagination(per_page: 25)

Set default pagination options at the controller level.

```ruby
class UsersController < ApplicationController
  include BetterController
  include BetterController::Utils::Pagination

  configure_pagination per_page: 50
end
```

### paginate(collection)

Paginate a collection based on request parameters.

```ruby
@users = paginate(User.all)
# Respects params[:page] and params[:per_page]
```

### pagination_meta(collection)

Generate pagination metadata for JSON responses.

```ruby
respond_with_success(
  users.map { |u| serialize(u) },
  meta: pagination_meta(users)
)
```

**Returns:**
```ruby
{
  current_page: 1,
  total_pages: 10,
  total_count: 250,
  per_page: 25
}
```

---

## Parameter Helpers

Methods available when including `BetterController::Utils::ParamsHelpers`.

### boolean_param(key, default: false)

Parse a parameter as boolean.

```ruby
boolean_param(:active)           # "true" -> true, "1" -> true
boolean_param(:featured, default: true)
```

### integer_param(key, default: nil)

Parse a parameter as integer.

```ruby
integer_param(:page)             # "5" -> 5
integer_param(:limit, default: 10)
```

### array_param(key)

Parse a parameter as array.

```ruby
array_param(:ids)                # "1,2,3" -> [1, 2, 3]
array_param(:tags)               # ["a", "b"] -> ["a", "b"]
```

### date_param(key, default: nil)

Parse a parameter as date.

```ruby
date_param(:start_date)          # "2024-01-15" -> Date object
date_param(:end_date, default: Date.current)
```

### datetime_param(key, default: nil)

Parse a parameter as datetime.

```ruby
datetime_param(:scheduled_at)    # ISO8601 string -> DateTime object
```
