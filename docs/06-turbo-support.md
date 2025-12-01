# Turbo Support

BetterController provides built-in support for Hotwire Turbo Frames and Turbo Streams.

---

## Overview

The TurboSupport concern provides helpers for detecting Turbo requests and rendering Turbo Stream responses. It's automatically included when using `include BetterController`.

## Turbo Frames vs Turbo Streams

Understanding the difference is important:

### Turbo Frames

- **Single target**: Updates one element at a time
- **Automatic**: Browser sends `Turbo-Frame` header, Rails handles the rest
- **Navigation**: When you click a link inside a `<turbo-frame>`, only that frame updates
- **Explicit DSL**: Use `turbo_frame {}` handler for explicit control over rendering

```erb
<%# In your view %>
<turbo-frame id="user_form">
  <%= render 'form', user: @user %>
</turbo-frame>

<%# Links inside target the same frame automatically %>
<%= link_to 'Edit', edit_user_path(@user) %>
```

### Turbo Streams

- **Multiple targets**: Updates many elements in one response
- **Explicit**: You define each action (append, replace, remove, etc.)
- **Mutations**: Use for complex DOM changes like adding/removing items
- **DSL provided**: BetterController has a full TurboStreamBuilder DSL

```ruby
turbo_stream do
  prepend :users_list, partial: 'user_row'  # Add to list
  update :users_count, partial: 'count'      # Update counter
  remove :empty_state                        # Remove empty message
  flash type: :notice, message: 'Created!'   # Show flash
end
```

## Turbo Frame DSL

BetterController provides an explicit `turbo_frame {}` DSL handler for complete control over Turbo Frame requests. This follows the same pattern as `html {}`, `json {}`, and `turbo_stream {}` handlers.

### Basic Usage

```ruby
action :index do
  service Users::IndexService
  page Users::IndexPage

  on_success do
    html { render_page }

    turbo_frame do
      component Users::ListComponent, locals: { title: 'Users' }
    end

    turbo_stream do
      replace :users_list, component: Users::ListComponent
    end

    json { render json: @result }
  end
end
```

### Turbo Frame Builder Options

The `turbo_frame {}` block supports three rendering modes:

#### Render a ViewComponent

```ruby
turbo_frame do
  component Users::ListComponent, locals: { users: @users, count: @total }
end
```

#### Render a Partial

```ruby
turbo_frame do
  partial 'users/list', locals: { users: @users }
end
```

#### Render Page Config

```ruby
turbo_frame do
  render_page status: :ok
end
```

### Layout Control

By default, Turbo Frame responses render without layout (`layout: false`). You can override this:

```ruby
turbo_frame do
  component Users::ListComponent
  layout true  # Include layout in response
end
```

### Fallback Behavior

When a Turbo Frame request is received but no `turbo_frame {}` handler is defined, BetterController falls back to the `html {}` handler. This follows Rails standard behavior where Turbo Frame requests have the same Accept header as HTML requests.

| Request Type | Handler | Fallback |
|--------------|---------|----------|
| HTML normale | `html {}` | Rails standard render |
| Turbo Frame | `turbo_frame {}` | `html {}` (Rails standard) |
| Turbo Stream | `turbo_stream {}` | Default turbo streams |
| JSON | `json {}` | Render json |

### Complete Example

```ruby
action :index do
  service Users::IndexService
  page Users::IndexPage

  on_success do
    html { render_page }

    turbo_frame do
      component Users::ListComponent, locals: { title: 'Users' }
    end

    turbo_stream do
      replace :users_list, component: Users::ListComponent
      flash type: :notice, message: 'Loaded!'
    end

    json { render json: @result }
  end

  on_error :validation do
    html { render_page status: :unprocessable_entity }

    turbo_frame do
      partial 'users/error_form', locals: { errors: @result[:errors] }
    end

    turbo_stream do
      replace :user_form, component: UserFormComponent
      form_errors errors: @result[:errors]
    end
  end
end
```

## Detection Methods

### turbo_frame_request?

Check if the request is from a Turbo Frame:

```ruby
if turbo_frame_request?
  render partial: 'form', layout: false
else
  render :edit
end
```

### turbo_stream_request?

Check if the request accepts Turbo Streams:

```ruby
if turbo_stream_request?
  render turbo_stream: turbo_stream.replace(:user, partial: 'user')
else
  redirect_to users_path
end
```

### current_turbo_frame

Get the ID of the requesting Turbo Frame:

```ruby
frame_id = current_turbo_frame
# => "user_form" (from Turbo-Frame header)
```

### turbo_native_app?

Check if request is from a Turbo Native mobile app:

```ruby
if turbo_native_app?
  # Adjust response for native app
end
```

## Stream Builder Methods

Build individual Turbo Streams:

### stream_append

Append content to a target:

```ruby
stream_append(:users_list, partial: 'users/user', locals: { user: @user })
stream_append(:users_list, component: UserRowComponent)
stream_append(:notifications, html: '<div>New notification</div>')
```

### stream_prepend

Prepend content to a target:

```ruby
stream_prepend(:messages, partial: 'messages/message')
```

### stream_replace

Replace an entire element:

```ruby
stream_replace(:user_1, partial: 'users/user', locals: { user: @user })
stream_replace(@user, component: UserCardComponent)  # Uses dom_id(@user)
```

### stream_update

Update element's inner HTML:

```ruby
stream_update(:counter, html: '<span>42</span>')
stream_update(:status, partial: 'shared/status')
```

### stream_remove

Remove an element:

```ruby
stream_remove(:notification_5)
stream_remove(@user)  # Uses dom_id(@user)
```

### stream_before / stream_after

Insert content before or after a target:

```ruby
stream_before(:user_5, partial: 'users/user', locals: { user: @new_user })
stream_after(:header, component: AlertComponent)
```

### stream_flash

Update flash message:

```ruby
stream_flash(type: :notice, message: 'User created successfully!')
stream_flash(type: :alert, message: 'Something went wrong')
```

Uses the `shared/flash` partial by default.

### stream_form_errors

Update form errors display:

```ruby
stream_form_errors(@user.errors)
stream_form_errors(@user.errors, target: :custom_errors)
```

Uses the `shared/form_errors` partial by default.

## Rendering Multiple Streams

### render_streams

Render multiple streams at once:

```ruby
def create
  @user = User.create(user_params)

  render_streams([
    { action: :append, target: :users_list, partial: 'users/user', locals: { user: @user } },
    { action: :update, target: :users_count, partial: 'users/count' },
    { action: :remove, target: :empty_state }
  ])
end
```

### respond_with_turbo_stream

Conditionally respond with Turbo Streams:

```ruby
def update
  @user.update(user_params)

  respond_with_turbo_stream do |streams|
    streams << stream_replace(@user, partial: 'users/user')
    streams << stream_flash(type: :notice, message: 'Updated!')
  end
end
```

Falls back to normal rendering if not a Turbo Stream request.

## Turbo-Compatible Redirect

### turbo_redirect_to

Redirect with Turbo-compatible status code (303):

```ruby
def create
  @user = User.create(user_params)
  turbo_redirect_to users_path
end

# With custom options
turbo_redirect_to user_path(@user), notice: 'Created!'
```

## Rendering in Frames

### render_in_frame

Helper method for manual Turbo Frame handling:

```ruby
def edit
  @user = User.find(params[:id])
  render_in_frame  # Renders without layout if Turbo Frame request
end
```

**Note:** When using the Action DSL, prefer the explicit `turbo_frame {}` handler for better control and clarity.

## Using with Action DSL

The Action DSL integrates Turbo Frames and Streams seamlessly:

```ruby
action :create do
  service Users::CreateService

  on_success do
    html { redirect_to users_path }

    turbo_frame do
      component UserRowComponent
    end

    turbo_stream do
      prepend :users_list, component: UserRowComponent
      update :users_count, partial: 'users/count'
      flash type: :notice, message: 'User created!'
    end
  end

  on_error :validation do
    html { render_page status: :unprocessable_entity }

    turbo_frame do
      partial 'users/form', locals: { errors: @result[:errors] }
    end

    turbo_stream do
      replace :user_form, component: UserFormComponent
      form_errors errors: @result[:errors]
    end
  end
end
```

## Stream Content Options

Each stream builder accepts these content options:

| Option | Description |
|--------|-------------|
| `partial:` | Render a partial |
| `component:` | Render a ViewComponent |
| `html:` | Raw HTML string |
| `locals:` | Local variables for partial/component |

```ruby
# Using partial
stream_replace(:user, partial: 'users/user', locals: { user: @user })

# Using component
stream_replace(:user, component: UserCardComponent)

# Using raw HTML
stream_update(:counter, html: "<span>#{@count}</span>")
```

## Target Resolution

Targets can be:

```ruby
# String or Symbol - used as-is
stream_replace(:users_list, ...)
stream_replace('user_form', ...)

# ActiveRecord model - uses dom_id
stream_replace(@user, ...)  # => target: "user_123"
stream_remove(@comment)      # => target: "comment_456"
```

## Configuration

Configure Turbo settings in the initializer:

```ruby
BetterController.configure do |config|
  config.turbo_enabled = true
  config.turbo_default_frame = nil
  config.turbo_auto_flash = true
  config.turbo_auto_form_errors = true
end
```

## Required Partials

Ensure these partials exist for flash and form errors:

```erb
<%# app/views/shared/_flash.html.erb %>
<% flash.each do |type, message| %>
  <div class="flash flash-<%= type %>"><%= message %></div>
<% end %>

<%# app/views/shared/_form_errors.html.erb %>
<% if errors.any? %>
  <div class="form-errors">
    <ul>
      <% errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```
