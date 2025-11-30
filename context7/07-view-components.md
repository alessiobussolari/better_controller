# View Components

ViewComponent integration for page rendering.

---

## Configuration

### Set Component Namespace

```ruby
BetterController.configure do |config|
  config.html_page_component_namespace = 'Templates'
end
```

--------------------------------

## Page Config Rendering

### render_page_config

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

--------------------------------

### With Status

```ruby
render_page_config(@page_config, status: :ok)
render_page_config(@page_config, status: :unprocessable_entity)
```

--------------------------------

## Action DSL Integration

### page Declaration

```ruby
action :show do
  service Users::ShowService
  page Users::ShowPage
end
```

--------------------------------

### component Declaration

```ruby
action :index do
  component Users::ListComponent
end

action :index do
  component Users::ListComponent, locals: { title: 'Users' }
end
```

--------------------------------

### page_config Modifier

```ruby
action :show do
  service Users::ShowService

  page_config do |config|
    config[:extra_data] = computed_value
  end
end
```

--------------------------------

## Component in Responses

### In Success Handler

```ruby
on_success do
  html { render_component UserDetailComponent, locals: { user: @result[:resource] } }
end
```

--------------------------------

### In Turbo Streams

```ruby
on_success do
  turbo_stream do
    append :users, component: UserRowComponent
    replace :header, component: PageHeaderComponent
  end
end
```

--------------------------------

## Auto-Provided Locals

### Available in Components

```ruby
# These are automatically passed:
result      # @result from action
resource    # @result[:resource]
collection  # @result[:collection]
```

--------------------------------

## Page Class Example

### Define Page Class

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

--------------------------------

## Component Structure

### Recommended Organization

```
app/components/
├── templates/
│   ├── index/
│   │   └── page_component.rb
│   ├── show/
│   │   └── page_component.rb
│   └── edit/
│       └── page_component.rb
└── users/
    ├── list_component.rb
    ├── row_component.rb
    └── form_component.rb
```

--------------------------------

## Page Component Example

### Component Class

```ruby
class Templates::Show::PageComponent < ViewComponent::Base
  def initialize(config:)
    @config = config
    @resource = config[:resource]
    @title = config[:title]
  end
end
```

--------------------------------

### Component Template

```erb
<%# templates/show/page_component.html.erb %>
<div class="page page-show">
  <h1><%= @title %></h1>
  <div class="content">
    <%= render resource_component %>
  </div>
</div>
```

--------------------------------

## Direct Rendering

### Rails Native

```ruby
def show
  @user = User.find(params[:id])
  render UserDetailComponent.new(user: @user)
end
```

--------------------------------

### In Turbo Streams

```ruby
render turbo_stream: [
  turbo_stream.append(:users, UserRowComponent.new(user: @user)),
  turbo_stream.update(:flash, FlashComponent.new(type: :notice))
]
```

--------------------------------
