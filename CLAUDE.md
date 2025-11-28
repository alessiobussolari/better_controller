# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BetterController is a Ruby gem that provides standardized, maintainable Rails controller patterns with built-in service layer, serialization, pagination, and error handling.

## Commands

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

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

The gem is organized into four main namespaces under `lib/better_controller/`:

- **Controllers** - Controller mixins and helpers
  - `ResourcesController` - RESTful CRUD actions (index, show, create, update, destroy)
  - `Base` - Core controller functionality
  - `ResponseHelpers` - `respond_with_success` and `respond_with_error` methods
  - `ActionHelpers` - Class-level controller configuration

- **Services** - Business logic layer
  - `Service` - Base class with `all`, `find`, `create`, `update`, `destroy` methods
  - Services use ancestry parameters for nested resource support

- **Serializers** - JSON serialization
  - `Serializer` module with DSL: `attributes`, `methods`, `associations`
  - Handles both single resources and collections automatically

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

  # Must implement:
  def resource_service_class; UserService; end
  def resource_params_root_key; :user; end
end
```

**Service classes** must implement `resource_class` method returning the ActiveRecord model.

**Serializers** use class-level DSL:
```ruby
class UserSerializer
  include BetterController::Serializers::Serializer
  attributes :id, :name, :email
  methods :full_name
end
```

### Response Format

All API responses follow a consistent structure:
```json
{
  "data": { ... },
  "message": "...",
  "meta": { "pagination": { ... } }
}
```

### Generators

```bash
rails generate better_controller:install           # Create initializer
rails generate better_controller:controller Users  # Generate controller + service + serializer
```

## Dependencies

- Ruby >= 3.0.0
- Rails >= 6.0 (actionpack, activesupport)
- Kaminari for pagination
- Zeitwerk for autoloading
