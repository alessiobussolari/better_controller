# Getting Started with BetterController

BetterController is a Ruby gem for building modern Rails controllers with a declarative DSL, Hotwire/Turbo support, and ViewComponent integration.

## Installation

Add to your Gemfile:

```ruby
gem 'better_controller'
```

Then run:

```bash
bundle install
```

### Optional Dependencies

For full Turbo and ViewComponent support:

```ruby
gem 'turbo-rails', '>= 1.0'
gem 'view_component', '>= 3.0'
```

## Basic Usage

### HTML Controllers

Include `BetterController` in your controller for full HTML/Turbo/ViewComponent support:

```ruby
class UsersController < ApplicationController
  include BetterController

  action :index do
    service Users::IndexService
  end

  action :show do
    service Users::ShowService
  end

  action :create do
    service Users::CreateService

    on_success do
      html { redirect_to users_path }
      turbo_stream do
        prepend :users_list
        update :flash
      end
    end

    on_error :validation do
      html { render_page status: :unprocessable_entity }
    end
  end
end
```

### API Controllers

For JSON APIs, use `BetterControllerApi`:

```ruby
class Api::UsersController < ApplicationController
  include BetterControllerApi

  def index
    users = User.all
    respond_with_success(users)
  end

  def show
    user = User.find(params[:id])
    respond_with_success(user)
  rescue ActiveRecord::RecordNotFound => e
    respond_with_error(e, status: :not_found)
  end
end
```

## Service Integration

BetterController works with service objects that return a result hash:

```ruby
class Users::IndexService
  def call(params:, **options)
    users = User.all.order(created_at: :desc)

    {
      success: true,
      collection: users,
      page_config: {
        type: :index,
        title: 'Users',
        items: users
      }
    }
  end
end
```

## Requirements

- Ruby >= 3.0
- Rails >= 6.0
- Optional: turbo-rails >= 1.0
- Optional: view_component >= 3.0
