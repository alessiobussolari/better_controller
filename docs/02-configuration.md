# Configuration

BetterController uses a Kaminari-style configuration system.

---

## Configuration File

Generate the initializer:

```bash
rails generate better_controller:install
```

This creates `config/initializers/better_controller.rb`:

```ruby
BetterController.configure do |config|
  # Pagination
  config.pagination_enabled = true
  config.pagination_per_page = 25

  # Serialization
  config.serialization_include_root = false
  config.serialization_camelize_keys = true

  # Error handling
  config.error_handling_log_errors = true
  config.error_handling_detailed_errors = true

  # HTML
  config.html_page_component_namespace = 'Templates'
  config.html_flash_partial = 'shared/flash'
  config.html_form_errors_partial = 'shared/form_errors'

  # Turbo
  config.turbo_enabled = true
  config.turbo_default_frame = nil
  config.turbo_auto_flash = true
  config.turbo_auto_form_errors = true

  # Wrapped responses (for BetterService integration)
  config.wrapped_responses_class = nil

  # API version (included in all API responses)
  config.api_version = 'v1'
end
```

## Configuration Options

### Pagination

| Option | Default | Description |
|--------|---------|-------------|
| `pagination_enabled` | `true` | Enable pagination globally |
| `pagination_per_page` | `25` | Default items per page |

### Serialization

| Option | Default | Description |
|--------|---------|-------------|
| `serialization_include_root` | `false` | Include root key in JSON |
| `serialization_camelize_keys` | `true` | Convert keys to camelCase |

### Error Handling

| Option | Default | Description |
|--------|---------|-------------|
| `error_handling_log_errors` | `true` | Log errors to Rails logger |
| `error_handling_detailed_errors` | `true` | Include detailed error info |

### HTML/ViewComponent

| Option | Default | Description |
|--------|---------|-------------|
| `html_page_component_namespace` | `'Templates'` | Namespace for page components |
| `html_flash_partial` | `'shared/flash'` | Partial for flash messages |
| `html_form_errors_partial` | `'shared/form_errors'` | Partial for form errors |

### Turbo/Hotwire

| Option | Default | Description |
|--------|---------|-------------|
| `turbo_enabled` | `true` | Enable Turbo support |
| `turbo_default_frame` | `nil` | Default Turbo Frame ID |
| `turbo_auto_flash` | `true` | Auto-update flash in streams |
| `turbo_auto_form_errors` | `true` | Auto-update form errors |

### Wrapped Responses

| Option | Default | Description |
|--------|---------|-------------|
| `wrapped_responses_class` | `nil` | Result wrapper class (e.g., `BetterController::Result`) |

When set, the Action DSL will automatically unwrap results from this class.

### API

| Option | Default | Description |
|--------|---------|-------------|
| `api_version` | `'v1'` | Version included in API response meta |

## Accessing Configuration

```ruby
# Get configuration
BetterController.config
BetterController.configuration  # alias

# Get specific option
BetterController.config.pagination_per_page

# Check if feature is enabled
BetterController.config.turbo_enabled?
BetterController.config.wrapped_responses_enabled?

# Legacy hash-style access (backward compatibility)
BetterController.config[:pagination]  # => { enabled: true, per_page: 25 }
```

## Reset Configuration (Testing)

```ruby
# In test setup
BetterController.reset_config!
```
