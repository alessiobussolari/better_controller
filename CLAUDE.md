# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BetterController is a Ruby gem that provides standardized, maintainable Rails controller patterns with declarative DSL, Hotwire/Turbo support, ViewComponent integration, pagination, and error handling.

**Note:** BetterController is BYOS (Bring Your Own Services/Serializers). It does NOT provide built-in services or serializers - use your preferred patterns (Interactor, Trailblazer, PORO, ActiveModel::Serializers, Blueprinter, JBuilder, etc.).

## Commands

```bash
# Install dependencies
bundle install

# Run unit tests
bundle exec rspec spec/better_controller

# Run integration tests (require Rails)
INTEGRATION_TESTS=true bundle exec rspec spec/integration spec/generators

# Run a single test file
bundle exec rspec spec/better_controller/resources_controller_spec.rb

# Run a specific test by line number
bundle exec rspec spec/better_controller/resources_controller_spec.rb:42

# Run linter
bundle exec rubocop

# Run linter with auto-fix
bundle exec rubocop -a

# Run all checks (tests + linter)
bundle exec rake

# Build the gem
bundle exec rake build

# Install gem locally
bundle exec rake install
```

## Architecture

### Core Module Structure

The gem is organized under `lib/better_controller/`:

- **Controllers** - Controller mixins and helpers
  - `ResourcesController` - RESTful CRUD actions (index, show, create, update, destroy)
  - `Base` - Core controller functionality
  - `ResponseHelpers` - `respond_with_success` and `respond_with_error` methods
  - `ActionHelpers` - Class-level controller configuration

- **DSL** - Declarative action definition
  - `ActionDsl` - Define actions with `action :name do ... end`
  - `ActionBuilder` - Build action configurations
  - `ResponseBuilder` - Build response handlers
  - `TurboStreamBuilder` - Build Turbo Stream responses

- **Rendering** - View rendering utilities
  - `PageConfigRenderer` - Render ViewComponents based on page_config
  - `ComponentRenderer` - Direct ViewComponent rendering

- **Utils** - Shared utilities
  - `Pagination` - Kaminari-based pagination with metadata
  - `ParameterValidation` - Parameter validation
  - `ParamsHelpers` - Parameter processing utilities
  - `Logging` - Enhanced logging

### Key Patterns

**Including in a controller:**
```ruby
class ApplicationController < ActionController::Base
  include BetterController
end
```

**Using ResourcesController:**
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

  # Optional: customize serialization
  def serialize_resource(resource)
    resource.as_json(only: [:id, :name, :email])
  end
end
```

### Response Format

All API responses follow a consistent structure:
```json
{
  "data": { ... },
  "meta": { "version": "v1" }
}
```

The version is configurable via `BetterController.config.api_version`.

### Generators

```bash
rails generate better_controller:install           # Create initializer
rails generate better_controller:controller Users  # Generate controller
```

## Dependencies

- Ruby >= 3.0.0
- Rails >= 6.0 (actionpack, activesupport)
- Kaminari for pagination
- Zeitwerk for autoloading
- Optional: turbo-rails >= 1.0
- Optional: view_component >= 3.0
