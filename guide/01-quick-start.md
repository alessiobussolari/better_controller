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

## Next Steps

- Read the [Configuration Guide](../docs/02-configuration.md) to customize settings
- Learn about the [Action DSL](../docs/04-action-dsl.md) for advanced patterns
- Build an [API Controller](02-building-api.md) or [HTML App](03-building-html-app.md)
