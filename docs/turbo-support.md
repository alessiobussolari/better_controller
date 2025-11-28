# Turbo Support

BetterController provides built-in support for Hotwire Turbo Frames and Turbo Streams.

## Turbo Frame Detection

Check the request context in your actions:

```ruby
def show
  if turbo_frame_request?
    render partial: 'user_card', locals: { user: @user }
  else
    render :show
  end
end
```

### Available Helpers

```ruby
turbo_frame_request?    # Is this a Turbo Frame request?
turbo_stream_request?   # Is this a Turbo Stream request?
current_turbo_frame     # Get the current Turbo Frame ID
turbo_native_app?       # Is this from a Turbo Native app?
```

## Turbo Stream Actions

Build Turbo Stream responses declaratively in action handlers:

```ruby
on_success do
  turbo_stream do
    append :notifications, partial: 'shared/notification'
    prepend :items_list
    replace :item_counter
    update :flash
    remove :loading_spinner
  end
end
```

### Available Stream Actions

| Action | Description |
|--------|-------------|
| `append(target, ...)` | Append content to target |
| `prepend(target, ...)` | Prepend content to target |
| `replace(target, ...)` | Replace target element |
| `update(target, ...)` | Update target's innerHTML |
| `remove(target)` | Remove target element |
| `before(target, ...)` | Insert before target |
| `after(target, ...)` | Insert after target |

### Content Options

Each stream action accepts:

```ruby
turbo_stream do
  # Using a partial
  append :list, partial: 'items/item', locals: { item: @item }

  # Using a component
  update :counter, component: CounterComponent

  # With custom locals for component
  replace :user, component: UserCardComponent, locals: { user: @user }
end
```

## Stream Helpers

Build individual streams outside of action blocks:

```ruby
stream_append(:list, partial: 'item')
stream_prepend(:list, partial: 'item')
stream_replace(:item, partial: 'item')
stream_update(:counter, partial: 'counter')
stream_remove(:notification)
stream_before(:item, partial: 'new_item')
stream_after(:item, partial: 'new_item')
```

## Search/Filter Pattern

Handle initial page load and subsequent filter updates:

```ruby
action :index do
  service Users::IndexService

  on_success do
    # HTML request: render full page
    html { render_page }

    # Turbo Stream request (search/filter): update only changed elements
    turbo_stream do
      replace :users_table
      update :users_count
      update :active_filters
      update :pagination
    end
  end
end
```

**View with Turbo Frame:**

```erb
<%# users/index.html.erb %>
<div id="users_count"><%= @page_config[:count] %> results</div>

<div id="active_filters">
  <% @page_config[:filters].each do |filter| %>
    <%= render filter %>
  <% end %>
</div>

<%= turbo_frame_tag :users_table do %>
  <%= render 'users/table', users: @page_config[:items] %>
<% end %>

<div id="pagination">
  <%= render 'shared/pagination', pagination: @page_config[:pagination] %>
</div>
```

**Search form with Turbo Stream:**

```erb
<%= form_with url: users_path, method: :get, data: { turbo_stream: true } do |f| %>
  <%= f.search_field :q, placeholder: "Search..." %>
  <%= f.select :status, options_for_select(statuses) %>
  <%= f.submit "Filter" %>
<% end %>
```

## Flash Messages with Turbo

BetterController automatically includes flash updates in Turbo Stream responses:

```ruby
on_success do
  turbo_stream do
    update :flash  # Updates flash partial
  end
end
```

The default partial is `shared/flash`. Customize in your app:

```erb
<%# app/views/shared/_flash.html.erb %>
<% flash.each do |type, message| %>
  <div class="alert alert-<%= type %>">
    <%= message %>
  </div>
<% end %>
```

## Form Errors with Turbo

Handle form validation errors:

```ruby
on_error :validation do
  turbo_stream do
    replace :user_form
    update :form_errors
  end
end
```

Default partial for errors is `shared/form_errors`:

```erb
<%# app/views/shared/_form_errors.html.erb %>
<% if errors.present? %>
  <div class="form-errors">
    <ul>
      <% errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```
