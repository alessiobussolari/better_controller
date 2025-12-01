# BetterController Documentation

Standardized Rails controller patterns with declarative DSL, Hotwire/Turbo support, ViewComponent integration, pagination, and error handling.

---

## Overview

BetterController is a Ruby gem that provides a clean, declarative way to build Rails controllers. It's **BYOS (Bring Your Own Services/Serializers)** - you use your preferred patterns.

## Features

- **Declarative Action DSL** - Define actions with `action :name do ... end`
- **ResourcesController** - RESTful CRUD with minimal setup
- **Response Helpers** - Standardized JSON API responses
- **Turbo Support** - Built-in Turbo Frames and Streams integration
- **ViewComponent Integration** - Render components with BetterPage
- **CSV Export** - Generate and download CSV files
- **Pagination** - Kaminari-based pagination with metadata
- **Parameter Helpers** - Type-casting and validation utilities
- **Error Handling** - Automatic exception handling and logging

## Documentation Index

| Document | Description |
|----------|-------------|
| [Getting Started](01-getting-started.md) | Installation and basic setup |
| [Configuration](02-configuration.md) | All configuration options |
| [Resources Controller](03-resources-controller.md) | RESTful CRUD actions |
| [Action DSL](04-action-dsl.md) | Declarative action definition |
| [Response Helpers](05-response-helpers.md) | API response formatting |
| [Turbo Support](06-turbo-support.md) | Hotwire/Turbo integration |
| [View Components](07-view-components.md) | ViewComponent rendering |
| [CSV Support](08-csv-support.md) | CSV export functionality |
| [Utilities](09-utilities.md) | Pagination, params, logging |
| [API Reference](10-api-reference.md) | Complete DSL reference |

## Quick Example

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService
    on_success do
      html { render_page }
      turbo_stream { replace :users_list }
      json { render json: @result }
    end
  end
end
```

## Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Kaminari (for pagination)
- Optional: turbo-rails >= 1.0
- Optional: view_component >= 3.0

## License

MIT License
