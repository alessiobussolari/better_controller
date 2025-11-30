# Resources Controller

RESTful CRUD controller with standardized actions.

---

## Include ResourcesController

### Basic Usage

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

## Required Methods

### resource_class

Return the ActiveRecord model class:

```ruby
def resource_class
  User
end
```

--------------------------------

### resource_params

Return permitted strong parameters:

```ruby
def resource_params
  params.require(:user).permit(:name, :email, :password)
end
```

--------------------------------

## Optional Overrides

### resource_scope

Customize the base query scope:

```ruby
def resource_scope
  current_user.organization.users.active
end
```

--------------------------------

### serialize_resource

Customize single resource serialization:

```ruby
def serialize_resource(resource)
  resource.as_json(only: [:id, :name, :email])
end
```

--------------------------------

### serialize_collection

Customize collection serialization:

```ruby
def serialize_collection(collection)
  collection.map { |r| serialize_resource(r) }
end
```

--------------------------------

### index_meta, show_meta, create_meta, update_meta, destroy_meta

Add custom metadata to responses:

```ruby
def index_meta
  { total_count: resource_scope.count }
end

def create_meta
  { created_at: Time.current }
end
```

--------------------------------

## Provided Actions

### index

```ruby
# GET /users
# Returns: { data: [...], meta: { version: "v1" } }
```

--------------------------------

### show

```ruby
# GET /users/:id
# Returns: { data: {...}, meta: { version: "v1" } }
```

--------------------------------

### create

```ruby
# POST /users
# Success: { data: {...}, meta: { version: "v1" } } (201)
# Error: { data: { error: {...} }, meta: { version: "v1" } } (422)
```

--------------------------------

### update

```ruby
# PATCH/PUT /users/:id
# Success: { data: {...}, meta: { version: "v1" } }
# Error: { data: { error: {...} }, meta: { version: "v1" } } (422)
```

--------------------------------

### destroy

```ruby
# DELETE /users/:id
# Success: { data: {...}, meta: { version: "v1" } }
```

--------------------------------

## Complete Example

### Full Controller Implementation

```ruby
class Api::V1::ProductsController < Api::ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Product
  end

  def resource_scope
    current_user.company.products.active
  end

  def resource_params
    params.require(:product).permit(:name, :price, :category_id)
  end

  def serialize_resource(resource)
    {
      id: resource.id,
      name: resource.name,
      price: resource.price.to_f,
      category: resource.category&.name
    }
  end

  def index_meta
    { total_products: resource_scope.count }
  end
end
```

--------------------------------
