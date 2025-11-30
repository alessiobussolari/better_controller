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
