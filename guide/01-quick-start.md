# Quick Start Guide

Get up and running with BetterController in 5 minutes.

---

## Step 1: Install the Gem

Add to your Gemfile:

```ruby
gem 'better_controller'
```

Run bundle:

```bash
bundle install
```

## Step 2: Generate Configuration

```bash
rails generate better_controller:install
```

This creates `config/initializers/better_controller.rb`.

## Step 3: Include in Your Controller

### Option A: HTML Controller with Turbo

```ruby
class ApplicationController < ActionController::Base
  include BetterController
end
```

### Option B: API Controller

```ruby
class Api::ApplicationController < ActionController::API
  include BetterControllerApi
end
```

### Option C: RESTful Resources

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

## Step 4: Your First Action with DSL

Create a controller with declarative actions:

```ruby
class ProductsController < ApplicationController
  include BetterController

  action :index do
    on_success do
      html { render :index }
      json { render json: Product.all }
    end
  end

  action :show do
    before { @product = Product.find(params[:id]) }

    on_success do
      html { render :show }
      json { render json: @product }
    end
  end

  action :create do
    params_key :product
    permit :name, :price, :description

    before do
      @product = Product.new(params.require(:product).permit(:name, :price, :description))
    end

    on_success do
      html { redirect_to products_path, notice: 'Created!' }
      json { render json: @product, status: :created }
    end

    on_error :validation do
      html { render :new, status: :unprocessable_entity }
      json { render json: { errors: @product.errors }, status: 422 }
    end
  end
end
```

## Step 5: Add Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :products
end
```

## What You Get

By including BetterController, you have access to:

- **Action DSL** - Define actions declaratively
- **Response Helpers** - `respond_with_success`, `respond_with_error`
- **Turbo Support** - Turbo Frames and Streams helpers
- **CSV Export** - `send_csv`, `generate_csv`
- **Parameter Helpers** - `boolean_param`, `integer_param`, etc.
- **Pagination** - `paginate`, `pagination_meta`

## Complete CLI Reference

### Step-by-Step Installation

```bash
# 1. Add to Gemfile
echo "gem 'better_controller'" >> Gemfile

# 2. Install dependencies
bundle install

# 3. Generate initializer
rails generate better_controller:install
# Output:
#   create  config/initializers/better_controller.rb
#   route   # BetterController routes can be added here

# 4. Generate your first controller
rails generate better_controller:controller Products
# Output:
#   create  app/controllers/products_controller.rb
```

### Generator Options

| Command | Description |
|---------|-------------|
| `rails g better_controller:install` | Create initializer |
| `rails g better_controller:controller NAME` | Create controller with all actions |
| `rails g better_controller:controller NAME actions...` | Create with specific actions |
| `rails g better_controller:controller NAME --model=X` | Use custom model name |

### Examples

```bash
# Generate Users controller with all CRUD actions
rails generate better_controller:controller Users

# Generate only index and show actions
rails generate better_controller:controller Users index show

# Generate controller for Account model
rails generate better_controller:controller Users --model=Account

# Generate namespaced API controller
rails generate better_controller:controller Api::V1::Users
```

### Development Commands

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/controllers/users_controller_spec.rb

# Run linter
bundle exec rubocop

# Auto-fix linter issues
bundle exec rubocop -a
```

## Next Steps

- Read the [Configuration Guide](../docs/02-configuration.md) to customize settings
- Learn about the [Action DSL](../docs/04-action-dsl.md) for advanced patterns
- Build an [API Controller](02-building-api.md) or [HTML App](03-building-html-app.md)
