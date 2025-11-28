# Configuration

BetterController can be configured with an initializer.

## Creating the Initializer

Create `config/initializers/better_controller.rb`:

```ruby
BetterController.configure do |config|
  # ViewComponent namespace for page types
  config.page_component_namespace = 'Templates'

  # Pagination settings
  config.pagination = {
    enabled: true,
    per_page: 25
  }

  # Error handling
  config.error_handling = {
    log_errors: true,
    detailed_errors: Rails.env.development?
  }

  # Serialization
  config.serialization = {
    include_root: false,
    camelize_keys: true
  }
end
```

## Configuration Options

### page_component_namespace

The namespace for page components. Default: `'Templates'`

```ruby
config.page_component_namespace = 'Templates'

# Components will be resolved as:
# :index -> Templates::Index::PageComponent
# :show  -> Templates::Show::PageComponent
```

### pagination

Default pagination settings:

```ruby
config.pagination = {
  enabled: true,      # Enable pagination by default
  per_page: 25        # Default items per page
}
```

Override in controllers:

```ruby
class UsersController < ApplicationController
  include BetterController

  configure_pagination enabled: true, per_page: 50
end
```

### error_handling

Error handling configuration:

```ruby
config.error_handling = {
  log_errors: true,           # Log errors to Rails logger
  detailed_errors: false      # Include stack traces in responses
}
```

### serialization

JSON serialization settings:

```ruby
config.serialization = {
  include_root: false,    # Include root key in JSON
  camelize_keys: true     # Convert keys to camelCase
}
```

## Accessing Configuration

Access configuration anywhere:

```ruby
BetterController.config.page_component_namespace
# => 'Templates'

BetterController.config.pagination[:per_page]
# => 25
```

## Per-Controller Configuration

Override settings in specific controllers:

```ruby
class Admin::UsersController < ApplicationController
  include BetterController

  # Override pagination
  configure_pagination enabled: true, per_page: 100

  # Custom serializer options
  def serialization_options
    { include_admin_fields: true }
  end
end
```

## Environment-Specific Settings

Use environment checks:

```ruby
BetterController.configure do |config|
  config.error_handling = {
    log_errors: true,
    detailed_errors: Rails.env.development? || Rails.env.test?
  }

  if Rails.env.production?
    config.pagination[:per_page] = 50
  end
end
```
