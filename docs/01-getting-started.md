# Getting Started

This guide covers installation and basic setup for BetterController.

---

## Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Kaminari gem (for pagination)
- Optional: turbo-rails >= 1.0 (for Turbo support)
- Optional: view_component >= 3.0 (for ViewComponent integration)

## Installation

Add to your Gemfile:

```ruby
gem 'better_controller'
```

Then run:

```bash
bundle install
```

## Generate Initializer

Run the install generator to create the configuration file:

```bash
rails generate better_controller:install
```

This creates `config/initializers/better_controller.rb` with default settings.

## Basic Usage

### HTML Controllers with Turbo Support

For HTML controllers with Turbo Frames/Streams support:

```ruby
class ApplicationController < ActionController::Base
  include BetterController
end
```

Or for specific controllers:

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService
  end
end
```

### API Controllers

For JSON API controllers:

```ruby
class Api::ApplicationController < ActionController::API
  include BetterControllerApi
end
```

### RESTful Resources

For standard CRUD operations:

```ruby
class ProductsController < ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Product
  end

  def resource_params
    params.require(:product).permit(:name, :price, :description)
  end
end
```

## What's Included

When you `include BetterController`, your controller gains:

- **Action DSL** - Declarative action definition
- **Turbo Support** - Turbo Frames and Streams helpers
- **ViewComponent Rendering** - Page config integration
- **CSV Support** - Export helpers
- **Response Helpers** - Standardized responses
- **Error Handling** - Automatic exception handling

## BYOS Philosophy

BetterController is **Bring Your Own Services/Serializers**. It does NOT provide:

- Service objects (use Interactor, Trailblazer, or plain Ruby classes)
- Serializers (use ActiveModel::Serializers, Blueprinter, JBuilder, or `as_json`)

You integrate your preferred patterns with the DSL.

## Next Steps

- [Configuration](02-configuration.md) - Customize settings
- [Action DSL](04-action-dsl.md) - Learn the declarative DSL
- [Resources Controller](03-resources-controller.md) - Standard CRUD setup
