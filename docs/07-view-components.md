# View Components

BetterController integrates with ViewComponent for rendering page configurations.

---

## Overview

The ViewComponent integration allows you to:

- Render components based on page_config from Page classes
- Use a namespace convention for page components
- Render components directly in Turbo Streams
- Work standalone (with `BetterController::Config`) or with BetterPage gem

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

Declare a page class to generate UI configuration:

```ruby
action :show do
  service Users::ShowService  # → data (Hash or Result)
  page Users::ShowPage        # → page config (Hash or Config object)
end
```

The page class receives data and current_user, and implements action methods:

```ruby
# Signature: Page.new(data, user: current_user).action_name
```

### Page Return Types

Pages can return different types. BetterController automatically normalizes them:

**1. Return Hash (simplest - automatically wrapped)**

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
      meta: { page_type: :show, editable: true }
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

**Important:** Services handle business logic and return data.
Pages handle UI configuration and return page config.
These are separate concerns - services should NOT return page_config.

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

## Turbo Frame Integration

When a Turbo Frame request is received and the `@page_config` contains a `klass` attribute, BetterController automatically renders the ViewComponent without layout.

### Automatic Component Rendering

```ruby
# Page class with klass
class Users::ShowPage
  def show
    {
      type: :show,
      resource: @data,
      klass: Users::ShowComponent  # This triggers automatic rendering
    }
  end
end

# For Turbo Frame requests:
# - @page_config.klass is Users::ShowComponent
# - BetterController renders: Users::ShowComponent.new(config: @page_config), layout: false

# For normal HTML requests:
# - Standard Rails render (looks for show.html.erb)
```

### With BetterPage::Config

When using BetterPage gem, the `klass` is typically set via `meta[:klass]`:

```ruby
class Users::IndexPage < BetterPage::IndexBasePage
  def index
    build_page  # Sets meta[:klass] automatically
  end
end
```

The flow:
1. **Normal HTML request** → Rails `render` (uses .html.erb view)
2. **Turbo Frame + klass** → ViewComponent `render(Component.new(config:), layout: false)`
3. **Turbo Stream** → TurboStreamBuilder DSL

### Important: View Files Required

For **normal HTML requests**, you must create the corresponding `.html.erb` view file:

```
app/views/users/
├── index.html.erb   # Required for GET /users (HTML)
├── show.html.erb    # Required for GET /users/:id (HTML)
├── new.html.erb     # Required for GET /users/new (HTML)
└── edit.html.erb    # Required for GET /users/:id/edit (HTML)
```

ViewComponents are **not** used as fallback for missing views. This is intentional - it follows Rails conventions where:
- Full page requests use ERB templates
- Turbo Frame requests can use ViewComponents (when `klass` is specified)

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

## Integration Modes

BetterController can work in two modes:

### Standalone Mode (Default)

Uses `BetterController::Config` for page configurations. No external gems required.

```ruby
# Configuration (default - no configuration needed)
BetterController.configure do |config|
  config.page_config_class = nil  # Uses BetterController::Config
end

# Page class returns Hash or BetterController::Config
class Users::IndexPage
  def initialize(data, user: nil)
    @data = data
  end

  def index
    { header: { title: 'Users' }, table: { items: @data } }
  end
end
```

### With BetterPage Gem

Uses `BetterPage::Config` for richer page configurations.

```ruby
# Configuration
BetterController.configure do |config|
  config.page_config_class = BetterPage::Config
end

# Page class extends BetterPage::Base
class Users::IndexPage < BetterPage::Base
  def initialize(data, user: nil)
    @data = data
    @user = user
  end

  def index
    BetterPage::Config.new(
      { header: { title: 'Users' }, table: { items: @data } },
      meta: { page_type: :index }
    )
  end
end
```

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     Service     │────▶│ BetterController│────▶│   Page Class    │
│                 │     │                 │     │                 │
│  Business Logic │     │  Orchestration  │     │  UI Config      │
│  Result: data   │     │  Normalization  │     │  Config: UI     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │ Config Object   │
                                               │                 │
                                               │ BetterController│
                                               │ ::Config        │
                                               │      OR         │
                                               │ BetterPage      │
                                               │ ::Config        │
                                               └─────────────────┘
```

### Key Points

1. **Services don't return page_config** - they only return data
2. **Pages receive data** - via `Page.new(data, user: current_user)`
3. **Pages return config** - Hash, `BetterController::Config`, or `BetterPage::Config`
4. **Controller normalizes** - Hash results are wrapped in `BetterController::Config`
5. **Flexible integration** - works standalone or with BetterPage gem
