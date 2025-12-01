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
- **ViewComponent support**: When `@page_config` has a `klass` attribute, BetterController renders the ViewComponent with `layout: false`

```erb
<%# In your view %>
<turbo-frame id="user_form">
  <%= render 'form', user: @user %>
</turbo-frame>

<%# Links inside target the same frame automatically %>
<%= link_to 'Edit', edit_user_path(@user) %>
```

**Note:** When using the Action DSL with a Page class that returns a `klass` attribute (ViewComponent class), BetterController automatically renders the component for Turbo Frame requests:

```ruby
action :edit do
  service Users::EditService
  page Users::EditPage  # Returns config with klass: EditComponent

  on_success do
    html { render_page }
    # For Turbo Frame + klass: renders EditComponent with layout: false
    # For normal HTML: uses Rails standard render (edit.html.erb)
  end
end
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

--------------------------------

### turbo_stream_request?

Check if the request accepts Turbo Streams:

```ruby
if turbo_stream_request?
  render turbo_stream: turbo_stream.replace(:user, partial: 'user')
else
  redirect_to users_path
end
```

--------------------------------

### current_turbo_frame

Get the ID of the requesting Turbo Frame:

```ruby
frame_id = current_turbo_frame
# => "user_form" (from Turbo-Frame header)
```

--------------------------------

### turbo_native_app?

Check if request is from a Turbo Native mobile app:

```ruby
if turbo_native_app?
  # Adjust response for native app
end
```

--------------------------------

## ViewComponent Rendering for Turbo Frames

When using BetterPage or a page config that includes a `klass` attribute, BetterController automatically renders the ViewComponent for Turbo Frame requests.

### How it works

1. Request comes in as Turbo Frame (header `Turbo-Frame` present)
2. BetterController checks if `@page_config` has a `klass` attribute
3. If yes: instantiates and renders the ViewComponent with `layout: false`
4. If no: uses Rails standard render (looks for .html.erb view)

--------------------------------

### Rails Convention

**Important:** For normal HTML requests (non-Turbo Frame), BetterController uses Rails standard `render`. This means:
- You **must create** the corresponding `.html.erb` view file (e.g., `index.html.erb`, `show.html.erb`)
- If the view file doesn't exist, Rails will raise a `ActionView::MissingTemplate` error
- ViewComponent is **only** used automatically for Turbo Frame requests when `@page_config` has a `klass` attribute

This follows Rails conventions - the full page is rendered via ERB templates, while Turbo Frame updates can use ViewComponents for better encapsulation.

--------------------------------

### Example with BetterPage

```ruby
# Page class returns BetterPage::Config with klass
class Users::IndexPage < BetterPage::IndexBasePage
  def index
    build_page  # Returns Config with klass = IndexViewComponent
  end
end

# Controller
action :index do
  service Users::IndexService
  page Users::IndexPage
end
```

For Turbo Frame requests with a `klass` in page_config:
```ruby
# BetterController automatically does:
render IndexViewComponent.new(config: @page_config), layout: false
```

For normal HTML requests (non-Turbo Frame):
```ruby
# BetterController uses Rails standard render:
render status: :ok  # Looks for index.html.erb
```

--------------------------------

### Manual Page Config with klass

```ruby
@page_config = {
  type: :index,
  items: @users,
  klass: Users::IndexComponent  # ViewComponent class
}
# For Turbo Frame: renders Users::IndexComponent.new(config: @page_config)
# For normal HTML: renders with Rails standard render
```

--------------------------------

## Stream Builder Methods

Build individual Turbo Streams:

### stream_append

```ruby
stream_append(:users_list, partial: 'users/user', locals: { user: @user })
stream_append(:users_list, component: UserRowComponent)
stream_append(:notifications, html: '<div>New notification</div>')
```

--------------------------------

### stream_prepend

```ruby
stream_prepend(:messages, partial: 'messages/message')
```

--------------------------------

### stream_replace

```ruby
stream_replace(:user_1, partial: 'users/user', locals: { user: @user })
stream_replace(@user, component: UserCardComponent)  # Uses dom_id(@user)
```

--------------------------------

### stream_update

```ruby
stream_update(:counter, html: '<span>42</span>')
stream_update(:status, partial: 'shared/status')
```

--------------------------------

### stream_remove

```ruby
stream_remove(:notification_5)
stream_remove(@user)  # Uses dom_id(@user)
```

--------------------------------

### stream_before / stream_after

```ruby
stream_before(:user_5, partial: 'users/user', locals: { user: @new_user })
stream_after(:header, component: AlertComponent)
```

--------------------------------

### stream_flash

```ruby
stream_flash(type: :notice, message: 'User created successfully!')
stream_flash(type: :alert, message: 'Something went wrong')
```

Uses the `shared/flash` partial by default.

--------------------------------

### stream_form_errors

```ruby
stream_form_errors(@user.errors)
stream_form_errors(@user.errors, target: :custom_errors)
```

Uses the `shared/form_errors` partial by default.

--------------------------------

## Rendering Multiple Streams

### render_streams

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

--------------------------------

### respond_with_turbo_stream

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

--------------------------------

## Turbo-Compatible Redirect

### turbo_redirect_to

```ruby
def create
  @user = User.create(user_params)
  turbo_redirect_to users_path
end

# With custom options
turbo_redirect_to user_path(@user), notice: 'Created!'
```

--------------------------------

## Rendering in Frames

### render_in_frame

Helper method for manual Turbo Frame handling:

```ruby
def edit
  @user = User.find(params[:id])
  render_in_frame  # Renders without layout if Turbo Frame request
end
```

**Note:** When using the Action DSL with a Page class that has a `klass` attribute, BetterController handles Turbo Frame rendering automatically. The `render_in_frame` helper is provided for manual controller implementations.

--------------------------------

## Action DSL Integration

### turbo_stream in on_success

```ruby
on_success do
  turbo_stream do
    prepend :users_list, component: UserRowComponent
    update :users_count, partial: 'users/count'
    flash type: :notice, message: 'User created!'
  end
end
```

--------------------------------

### turbo_stream in on_error

```ruby
on_error :validation do
  turbo_stream do
    replace :user_form, component: UserFormComponent
    form_errors errors: @result[:errors]
  end
end
```

--------------------------------

## Target Resolution

### Target types

```ruby
# String/Symbol - used as-is
stream_replace(:users_list, ...)
stream_replace('user_form', ...)

# ActiveRecord - uses dom_id
stream_replace(@user, ...)  # => "user_123"
stream_remove(@comment)      # => "comment_456"
```

--------------------------------

## Content Options

### partial, component, html

```ruby
# Partial
stream_replace(:user, partial: 'users/user', locals: { user: @user })

# Component
stream_replace(:user, component: UserCardComponent)

# HTML
stream_update(:counter, html: "<span>#{@count}</span>")
```

--------------------------------
