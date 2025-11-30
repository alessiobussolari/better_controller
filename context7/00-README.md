# BetterController

Standardized Rails controller patterns with declarative DSL, Turbo support, and ViewComponent integration.

---

## Quick Reference

### Include BetterController (HTML + Turbo)

```ruby
class ApplicationController < ActionController::Base
  include BetterController
end
```

--------------------------------

### Include BetterControllerApi (JSON API)

```ruby
class Api::ApplicationController < ActionController::API
  include BetterControllerApi
end
```

--------------------------------

### Include ResourcesController (CRUD)

```ruby
class UsersController < ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    User
  end

  def resource_params
    params.require(:user).permit(:name, :email)
  end
end
```

--------------------------------

## Key Features

| Feature | Module |
|---------|--------|
| Action DSL | `BetterController::Controllers::Concerns::ActionDsl` |
| Resources CRUD | `BetterController::Controllers::ResourcesController` |
| Response Helpers | `BetterController::Controllers::ResponseHelpers` |
| Turbo Support | `BetterController::Controllers::Concerns::TurboSupport` |
| CSV Export | `BetterController::Controllers::Concerns::CsvSupport` |
| Pagination | `BetterController::Utils::Pagination` |
| Params Helpers | `BetterController::Utils::ParamsHelpers` |

## Documentation Files

- [01-getting-started.md](01-getting-started.md) - Installation and setup
- [02-configuration.md](02-configuration.md) - Configuration options
- [03-resources-controller.md](03-resources-controller.md) - RESTful CRUD
- [04-action-dsl.md](04-action-dsl.md) - Declarative actions
- [05-response-helpers.md](05-response-helpers.md) - API responses
- [06-turbo-support.md](06-turbo-support.md) - Turbo integration
- [07-view-components.md](07-view-components.md) - ViewComponent rendering
- [08-csv-support.md](08-csv-support.md) - CSV export
- [09-pagination.md](09-pagination.md) - Pagination utilities
- [10-error-handling.md](10-error-handling.md) - Error handling
- [11-api-reference.md](11-api-reference.md) - Complete DSL reference

## Response Format

```json
{
  "data": { ... },
  "meta": { "version": "v1" }
}
```

--------------------------------

## BYOS Philosophy

BetterController is BYOS (Bring Your Own Services/Serializers):
- Does NOT provide service objects
- Does NOT provide serializers
- Use your preferred patterns (Interactor, Blueprinter, etc.)

--------------------------------
