# Getting Started

Installation and basic setup for BetterController.

---

## Installation

### Gemfile

Add to your Gemfile:

```ruby
gem 'better_controller'
```

--------------------------------

### Bundle Install

```bash
bundle install
```

--------------------------------

### Generate Initializer

```bash
rails generate better_controller:install
```

--------------------------------

## CLI Commands Reference

### Installation

```bash
bundle add better_controller
```

--------------------------------

### Install Generator

```bash
rails generate better_controller:install
```

Creates: `config/initializers/better_controller.rb`

--------------------------------

### Controller Generator

```bash
# All actions
rails generate better_controller:controller Users

# Specific actions
rails generate better_controller:controller Users index show create

# Custom model
rails generate better_controller:controller Users --model=Account

# Namespaced
rails generate better_controller:controller Admin::Users
```

--------------------------------

### Development Commands

```bash
# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Auto-fix linter issues
bundle exec rubocop -a
```

--------------------------------

## Basic Setup

### HTML Controller with Turbo

```ruby
class ApplicationController < ActionController::Base
  include BetterController
end
```

--------------------------------

### API Controller

```ruby
class Api::ApplicationController < ActionController::API
  include BetterControllerApi
end
```

--------------------------------

### RESTful Resources Controller

```ruby
class ProductsController < ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Product
  end

  def resource_params
    params.require(:product).permit(:name, :price)
  end
end
```

--------------------------------

## First Action with DSL

### Define Action

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService
    on_success do
      html { render_page }
      json { render json: @result }
    end
  end
end
```

--------------------------------

## Requirements

- Ruby >= 3.0.0
- Rails >= 6.0
- Kaminari (pagination)
- Optional: turbo-rails >= 1.0
- Optional: view_component >= 3.0

--------------------------------
