# Turbo Support

Hotwire Turbo Frames and Streams integration.

---

## Detection Methods

### turbo_frame_request?

Check if request is from Turbo Frame:

```ruby
if turbo_frame_request?
  render partial: 'form', layout: false
end
```

--------------------------------

### turbo_stream_request?

Check if request accepts Turbo Streams:

```ruby
if turbo_stream_request?
  render turbo_stream: turbo_stream.replace(:user, partial: 'user')
end
```

--------------------------------

### current_turbo_frame

Get requesting frame ID:

```ruby
frame_id = current_turbo_frame
# => "user_form"
```

--------------------------------

### turbo_native_app?

Check if from Turbo Native app:

```ruby
if turbo_native_app?
  # Adjust for native
end
```

--------------------------------

## Stream Builders

### stream_append

```ruby
stream_append(:users_list, partial: 'users/user', locals: { user: @user })
stream_append(:users_list, component: UserRowComponent)
stream_append(:notifications, html: '<div>New!</div>')
```

--------------------------------

### stream_prepend

```ruby
stream_prepend(:messages, partial: 'messages/message')
```

--------------------------------

### stream_replace

```ruby
stream_replace(:user_1, partial: 'users/user')
stream_replace(@user, component: UserCardComponent)
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
stream_remove(@user)  # Uses dom_id
```

--------------------------------

### stream_before / stream_after

```ruby
stream_before(:user_5, partial: 'users/user')
stream_after(:header, component: AlertComponent)
```

--------------------------------

### stream_flash

```ruby
stream_flash(type: :notice, message: 'User created!')
stream_flash(type: :alert, message: 'Error occurred')
```

--------------------------------

### stream_form_errors

```ruby
stream_form_errors(@user.errors)
stream_form_errors(@user.errors, target: :custom_errors)
```

--------------------------------

## Render Multiple Streams

### render_streams

```ruby
render_streams([
  { action: :append, target: :users, partial: 'users/user' },
  { action: :update, target: :count, partial: 'users/count' },
  { action: :remove, target: :empty_state }
])
```

--------------------------------

### respond_with_turbo_stream

```ruby
respond_with_turbo_stream do |streams|
  streams << stream_replace(@user, partial: 'users/user')
  streams << stream_flash(type: :notice, message: 'Updated!')
end
```

--------------------------------

## Redirect

### turbo_redirect_to

```ruby
turbo_redirect_to users_path
turbo_redirect_to user_path(@user), notice: 'Created!'
```

--------------------------------

## Render in Frame

### render_in_frame

```ruby
def edit
  @user = User.find(params[:id])
  render_in_frame  # No layout if Turbo Frame
end
```

--------------------------------

## Action DSL Integration

### turbo_stream in on_success

```ruby
on_success do
  turbo_stream do
    prepend :users_list, component: UserRowComponent
    update :users_count, partial: 'users/count'
    flash type: :notice, message: 'Created!'
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
{ action: :replace, target: :user, partial: 'users/user', locals: { user: @user } }

# Component
{ action: :replace, target: :user, component: UserCardComponent }

# HTML
{ action: :update, target: :counter, html: '<span>42</span>' }
```

--------------------------------
