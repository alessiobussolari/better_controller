# ViewComponent Integration

BetterController integrates seamlessly with ViewComponent for rendering UI components.

## Page Config Rendering

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

## Component Resolution

Components are resolved based on the page config type:

| Page Type | Component Class |
|-----------|-----------------|
| `:index` | `Templates::Index::PageComponent` |
| `:show` | `Templates::Show::PageComponent` |
| `:form` | `Templates::Form::PageComponent` |
| `:custom` | `Templates::Custom::PageComponent` |

Configure the namespace in the initializer:

```ruby
BetterController.configure do |config|
  config.page_component_namespace = 'Templates'  # Default
end
```

## Component Rendering Helpers

Render components directly in your controllers:

```ruby
# Render a single component
render_component UserCardComponent, locals: { user: @user }

# Render to string
html = render_component_to_string AvatarComponent, locals: { user: @user }

# Render a collection
render_component_collection users, UserRowComponent, item_key: :user
```

## Default Locals

Components automatically receive these locals:

| Local | Description |
|-------|-------------|
| `current_user` | Current user if available |
| `page_config` | The page configuration hash |
| `result` | The service result hash |
| `resource` | Single resource from result |
| `collection` | Collection from result |

## Direct Component Rendering

Use the `component` directive in actions to render ViewComponents directly:

```ruby
action :dashboard do
  component DashboardComponent
end

action :profile do
  component ProfileComponent, locals: { show_avatar: true }
end
```

## Page Class Integration

Create page classes that generate page_config:

```ruby
class Users::IndexPage
  def initialize(data:, user:, params:)
    @data = data
    @user = user
    @params = params
  end

  def to_config
    {
      type: :index,
      title: 'Users',
      items: @data[:collection],
      pagination: build_pagination,
      filters: build_filters
    }
  end

  private

  def build_pagination
    {
      current_page: @params[:page] || 1,
      total_pages: (@data[:collection].count / 25.0).ceil
    }
  end

  def build_filters
    [
      { type: :search, value: @params[:q] },
      { type: :status, value: @params[:status] }
    ]
  end
end
```

Use in your action:

```ruby
action :index do
  service Users::IndexService
  page Users::IndexPage  # Fallback if service doesn't provide page_config
end
```

## Creating Page Components

Example page component:

```ruby
# app/components/templates/index/page_component.rb
class Templates::Index::PageComponent < ViewComponent::Base
  def initialize(config:, current_user: nil, result: nil)
    @config = config
    @current_user = current_user
    @result = result
  end

  def title
    @config[:title]
  end

  def items
    @config[:items] || []
  end

  def pagination
    @config[:pagination]
  end
end
```

```erb
<%# app/components/templates/index/page_component.html.erb %>
<div class="page-header">
  <h1><%= title %></h1>
</div>

<div class="items-list">
  <% items.each do |item| %>
    <%= render item_component(item) %>
  <% end %>
</div>

<% if pagination %>
  <%= render PaginationComponent.new(**pagination) %>
<% end %>
```

## Modifying Page Config

Modify page_config from service in your action:

```ruby
action :admin_index do
  service Users::IndexService

  page_config do |config|
    config[:title] = "Admin: #{config[:title]}"
    config[:show_admin_actions] = true
    config[:columns] << :admin_notes
  end
end
```
