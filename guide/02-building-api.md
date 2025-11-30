# Building a JSON API

Create a complete JSON API controller with BetterController.

---

## Goal

Build a RESTful API for a `Product` resource with:
- Standard CRUD endpoints
- Consistent JSON response format
- Proper error handling
- Pagination

## Step 1: Setup Base API Controller

Create your API base controller:

```ruby
# app/controllers/api/application_controller.rb
class Api::ApplicationController < ActionController::API
  include BetterControllerApi
end
```

This gives you:
- Response helpers (`respond_with_success`, `respond_with_error`)
- Standard response format (`{data, meta: {version}}`)

## Step 2: Create Products Controller

### Option A: Using ResourcesController

For simple CRUD with minimal code:

```ruby
# app/controllers/api/products_controller.rb
class Api::ProductsController < Api::ApplicationController
  include BetterController::Controllers::ResourcesController

  private

  def resource_class
    Product
  end

  def resource_params
    params.require(:product).permit(:name, :price, :description, :category_id)
  end

  def resource_scope
    Product.includes(:category).order(created_at: :desc)
  end

  def serialize_resource(resource)
    {
      id: resource.id,
      name: resource.name,
      price: resource.price.to_f,
      description: resource.description,
      category: resource.category&.name,
      created_at: resource.created_at.iso8601
    }
  end

  def index_meta
    { total_count: resource_scope.count }
  end
end
```

### Option B: Using Action DSL

For more control over each action:

```ruby
# app/controllers/api/products_controller.rb
class Api::ProductsController < Api::ApplicationController
  include BetterController::Utils::Pagination

  configure_pagination per_page: 20

  action :index do
    on_success do
      json do
        products = paginate(Product.all)
        respond_with_success(
          products.map { |p| serialize_product(p) },
          meta: pagination_meta(products)
        )
      end
    end
  end

  action :show do
    before { @product = Product.find(params[:id]) }

    on_success do
      json { respond_with_success(serialize_product(@product)) }
    end

    on_error :not_found do
      json { respond_with_error('Product not found', status: :not_found) }
    end
  end

  action :create do
    params_key :product
    permit :name, :price, :description, :category_id

    before do
      @product = Product.new(product_params)
    end

    on_success do
      json do
        if @product.save
          respond_with_success(serialize_product(@product), status: :created)
        else
          respond_with_error(@product.errors)
        end
      end
    end
  end

  action :update do
    params_key :product
    permit :name, :price, :description, :category_id

    before { @product = Product.find(params[:id]) }

    on_success do
      json do
        if @product.update(product_params)
          respond_with_success(serialize_product(@product))
        else
          respond_with_error(@product.errors)
        end
      end
    end
  end

  action :destroy do
    before { @product = Product.find(params[:id]) }

    on_success do
      json do
        @product.destroy
        respond_with_success({ id: @product.id }, meta: { deleted: true })
      end
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :price, :description, :category_id)
  end

  def serialize_product(product)
    {
      id: product.id,
      name: product.name,
      price: product.price.to_f,
      description: product.description,
      category: product.category&.name,
      created_at: product.created_at.iso8601
    }
  end
end
```

## Step 3: Add Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    resources :products
  end
end
```

## Step 4: Test Your API

### List Products

```bash
curl http://localhost:3000/api/products
```

Response:
```json
{
  "data": [
    { "id": 1, "name": "Widget", "price": 29.99, ... },
    { "id": 2, "name": "Gadget", "price": 49.99, ... }
  ],
  "meta": {
    "version": "v1",
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

### Create Product

```bash
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": "New Item", "price": 19.99}}'
```

Response:
```json
{
  "data": { "id": 3, "name": "New Item", "price": 19.99, ... },
  "meta": { "version": "v1" }
}
```

### Validation Error

```bash
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"product": {"name": ""}}'
```

Response:
```json
{
  "data": {
    "error": {
      "messages": ["Name can't be blank"],
      "details": { "name": ["can't be blank"] }
    }
  },
  "meta": { "version": "v1" }
}
```

## Adding Search and Filters

```ruby
action :index do
  on_success do
    json do
      products = Product.all

      # Apply filters
      products = products.where(category_id: params[:category_id]) if params[:category_id]
      products = products.where('name ILIKE ?', "%#{params[:q]}%") if params[:q]
      products = products.where('price >= ?', params[:min_price]) if params[:min_price]
      products = products.where('price <= ?', params[:max_price]) if params[:max_price]

      products = paginate(products)

      respond_with_success(
        products.map { |p| serialize_product(p) },
        meta: pagination_meta(products)
      )
    end
  end
end
```

## Next Steps

- Add authentication (Devise, JWT, etc.)
- Add API versioning in routes
- Use a serializer gem (Blueprinter, AMS) for complex serialization
- Add rate limiting
