# View Components

BetterController integrates with ViewComponent for rendering page configurations.

---

## Overview

The ViewComponent integration allows you to:

- Render components based on page_config from services
- Use a namespace convention for page components
- Render components directly in Turbo Streams

## Configuration

Set the component namespace in your initializer:

```ruby
BetterController.configure do |config|
  config.html_page_component_namespace = 'Templates'
end
```

## Page Config Rendering

### render_page_config

Render a page based on configuration:

```ruby
def show
  @page_config = {
    type: :show,
    resource: @user,
    title: 'User Details'
  }

  render_page_config(@page_config)
end
```

The renderer resolves components based on the namespace:
- `Templates::Show::PageComponent`
- `Templates::Index::PageComponent`
- etc.

### With Status Code

```ruby
render_page_config(@page_config, status: :ok)
render_page_config(@page_config, status: :unprocessable_entity)
```

## Using with Action DSL

### page Declaration

Declare a page class for automatic page_config generation:

```ruby
action :show do
  service Users::ShowService
  page Users::ShowPage  # Generates page_config
end
```

The page class should implement `to_config`:

```ruby
class Users::ShowPage
  def initialize(data:, params:, user: nil)
    @data = data
    @params = params
    @user = user
  end

  def to_config
    {
      type: :show,
      resource: @data[:resource],
      title: "User: #{@data[:resource].name}"
    }
  end
end
```

### component Declaration

Render a component directly:

```ruby
action :index do
  component Users::ListComponent
end

# With locals
action :index do
  component Users::ListComponent, locals: { title: 'All Users' }
end
```

### page_config Modifier

Modify page_config from service result:

```ruby
action :show do
  service Users::ShowService

  page_config do |config|
    config[:extra_data] = computed_value
  end
end
```

## Component Rendering in Responses

### In Success Handlers

```ruby
on_success do
  html { render_component UserDetailComponent, locals: { user: @result[:resource] } }
end
```

### In Turbo Streams

```ruby
on_success do
  turbo_stream do
    append :users, component: UserRowComponent
    replace :header, component: PageHeaderComponent, locals: { title: 'Users' }
  end
end
```

## Component Locals

When rendering components, these locals are automatically available:

| Local | Source |
|-------|--------|
| `result` | `@result` from action |
| `resource` | `@result[:resource]` |
| `collection` | `@result[:collection]` |

```ruby
# Your component receives these automatically
class UserRowComponent < ViewComponent::Base
  def initialize(result: nil, resource: nil, **options)
    @user = resource
    @options = options
  end
end
```

## Page Component Structure

Recommended component organization:

```
app/components/
├── templates/
│   ├── index/
│   │   └── page_component.rb
│   ├── show/
│   │   └── page_component.rb
│   ├── new/
│   │   └── page_component.rb
│   └── edit/
│       └── page_component.rb
└── users/
    ├── list_component.rb
    ├── row_component.rb
    └── form_component.rb
```

## Example Page Component

```ruby
# app/components/templates/show/page_component.rb
class Templates::Show::PageComponent < ViewComponent::Base
  def initialize(config:)
    @config = config
    @resource = config[:resource]
    @title = config[:title]
  end
end
```

```erb
<%# app/components/templates/show/page_component.html.erb %>
<div class="page page-show">
  <h1><%= @title %></h1>
  <div class="content">
    <%= render resource_component %>
  </div>
</div>
```

## Direct Component Rendering

### render (Rails native)

Use Rails' built-in component rendering:

```ruby
def show
  @user = User.find(params[:id])
  render UserDetailComponent.new(user: @user)
end
```

### In Turbo Streams

```ruby
def create
  @user = User.create(user_params)

  render turbo_stream: [
    turbo_stream.append(:users, UserRowComponent.new(user: @user)),
    turbo_stream.update(:flash, FlashComponent.new(type: :notice, message: 'Created!'))
  ]
end
```

## Integration with BetterService

If using BetterService with a viewer pattern, page_config comes from the service:

```ruby
# Service returns page_config
class Users::ShowService
  def call(id:)
    user = User.find(id)

    BetterService::Result.new(
      resource: user,
      page_config: build_page_config(user)
    )
  end

  private

  def build_page_config(user)
    {
      type: :show,
      resource: user,
      title: user.name,
      breadcrumbs: [...]
    }
  end
end

# Controller uses it automatically
action :show do
  service Users::ShowService
  # page_config is extracted from result
end
```
