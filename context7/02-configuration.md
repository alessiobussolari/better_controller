# Configuration

BetterController configuration options.

---

## Configure Block

### Basic Configuration

```ruby
BetterController.configure do |config|
  config.pagination_per_page = 25
  config.api_version = 'v1'
  config.turbo_enabled = true
end
```

--------------------------------

## Pagination Options

### pagination_enabled

Enable/disable pagination globally:

```ruby
config.pagination_enabled = true  # default
```

--------------------------------

### pagination_per_page

Default items per page:

```ruby
config.pagination_per_page = 25  # default
```

--------------------------------

## Error Handling Options

### error_handling_log_errors

Log errors to Rails logger:

```ruby
config.error_handling_log_errors = true  # default
```

--------------------------------

### error_handling_detailed_errors

Include detailed error info in responses:

```ruby
config.error_handling_detailed_errors = true  # default
```

--------------------------------

## HTML Options

### html_page_component_namespace

Namespace for page components:

```ruby
config.html_page_component_namespace = 'Templates'  # default
```

--------------------------------

### html_flash_partial

Partial for flash messages:

```ruby
config.html_flash_partial = 'shared/flash'  # default
```

--------------------------------

### html_form_errors_partial

Partial for form errors:

```ruby
config.html_form_errors_partial = 'shared/form_errors'  # default
```

--------------------------------

## Turbo Options

### turbo_enabled

Enable Turbo support:

```ruby
config.turbo_enabled = true  # default
```

--------------------------------

### turbo_auto_flash

Auto-update flash in Turbo Streams:

```ruby
config.turbo_auto_flash = true  # default
```

--------------------------------

### turbo_auto_form_errors

Auto-update form errors in Turbo Streams:

```ruby
config.turbo_auto_form_errors = true  # default
```

--------------------------------

## API Options

### api_version

Version included in API response meta:

```ruby
config.api_version = 'v1'  # default
```

--------------------------------

## Wrapped Responses

### wrapped_responses_class

Set result wrapper class for service integration:

```ruby
config.wrapped_responses_class = BetterController::Result
```

--------------------------------

## Access Configuration

### Get Configuration

```ruby
BetterController.config
BetterController.configuration  # alias
```

--------------------------------

### Get Specific Option

```ruby
BetterController.config.pagination_per_page
BetterController.config.turbo_enabled?
```

--------------------------------

### Reset Configuration (Testing)

```ruby
BetterController.reset_config!
```

--------------------------------
