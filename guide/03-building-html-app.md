# Building an HTML App with Turbo

Create an HTML application using BetterController with Hotwire/Turbo support.

---

## Goal

Build a Products management interface with:
- Standard CRUD views
- Turbo Frames for modal forms
- Turbo Streams for real-time updates
- Flash messages
- Form error handling

## Prerequisites

Ensure you have:
- turbo-rails gem installed
- ViewComponent gem (optional but recommended)

## Step 1: Setup Application Controller

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include BetterController
end
```

## Step 2: Create Products Controller

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  action :index do
    before { @products = Product.order(created_at: :desc) }

    on_success do
      html { render :index }
    end
  end

  action :show do
    before { @product = Product.find(params[:id]) }

    on_success do
      html { render :show }
    end

    on_error :not_found do
      html { redirect_to products_path, alert: 'Product not found' }
    end
  end

  action :new do
    before { @product = Product.new }

    on_success do
      html { render :new }
    end
  end

  action :create do
    params_key :product
    permit :name, :price, :description

    before { @product = Product.new(product_params) }

    on_success do
      html do
        if @product.save
          redirect_to products_path, notice: 'Product created!'
        else
          render :new, status: :unprocessable_entity
        end
      end

      turbo_stream do
        if @product.save
          prepend :products_list, partial: 'products/product', locals: { product: @product }
          update :flash, partial: 'shared/flash'
          remove :new_product_modal
        else
          replace :product_form, partial: 'products/form', locals: { product: @product }
        end
      end
    end
  end

  action :edit do
    before { @product = Product.find(params[:id]) }

    on_success do
      html { render :edit }
    end
  end

  action :update do
    params_key :product
    permit :name, :price, :description

    before { @product = Product.find(params[:id]) }

    on_success do
      html do
        if @product.update(product_params)
          redirect_to products_path, notice: 'Product updated!'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      turbo_stream do
        if @product.update(product_params)
          replace @product, partial: 'products/product', locals: { product: @product }
          update :flash, partial: 'shared/flash'
          remove :edit_product_modal
        else
          replace :product_form, partial: 'products/form', locals: { product: @product }
        end
      end
    end
  end

  action :destroy do
    before { @product = Product.find(params[:id]) }

    on_success do
      html do
        @product.destroy
        redirect_to products_path, notice: 'Product deleted!'
      end

      turbo_stream do
        @product.destroy
        remove @product
        update :flash, partial: 'shared/flash'
        update :products_count, partial: 'products/count', locals: { count: Product.count }
      end
    end
  end

  private

  def product_params
    params.require(:product).permit(:name, :price, :description)
  end
end
```

## Step 3: Create Views

### Layout Partials

```erb
<%# app/views/shared/_flash.html.erb %>
<% flash.each do |type, message| %>
  <div class="alert alert-<%= type == 'notice' ? 'success' : 'danger' %>" role="alert">
    <%= message %>
  </div>
<% end %>
```

```erb
<%# app/views/shared/_form_errors.html.erb %>
<% if errors.any? %>
  <div class="alert alert-danger">
    <h4><%= pluralize(errors.count, "error") %> prohibited saving:</h4>
    <ul>
      <% errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

### Index View

```erb
<%# app/views/products/index.html.erb %>
<h1>Products</h1>

<div id="flash">
  <%= render 'shared/flash' %>
</div>

<p>
  <%= link_to 'New Product', new_product_path,
      data: { turbo_frame: 'modal' } %>
</p>

<div id="products_count">
  <%= render 'count', count: @products.count %>
</div>

<turbo-frame id="modal"></turbo-frame>

<div id="products_list">
  <%= render @products %>
</div>
```

### Product Partial

```erb
<%# app/views/products/_product.html.erb %>
<%= turbo_frame_tag product do %>
  <div class="product-card">
    <h3><%= product.name %></h3>
    <p class="price"><%= number_to_currency(product.price) %></p>
    <p><%= product.description %></p>
    <div class="actions">
      <%= link_to 'Edit', edit_product_path(product),
          data: { turbo_frame: 'modal' } %>
      <%= button_to 'Delete', product_path(product),
          method: :delete,
          data: { turbo_confirm: 'Are you sure?' } %>
    </div>
  </div>
<% end %>
```

### Form Partial

```erb
<%# app/views/products/_form.html.erb %>
<%= turbo_frame_tag 'modal' do %>
  <div id="product_form" class="modal">
    <%= form_with model: product do |f| %>
      <div id="form_errors">
        <%= render 'shared/form_errors', errors: product.errors if product.errors.any? %>
      </div>

      <div class="field">
        <%= f.label :name %>
        <%= f.text_field :name %>
      </div>

      <div class="field">
        <%= f.label :price %>
        <%= f.number_field :price, step: 0.01 %>
      </div>

      <div class="field">
        <%= f.label :description %>
        <%= f.text_area :description %>
      </div>

      <div class="actions">
        <%= f.submit %>
        <%= link_to 'Cancel', products_path, data: { turbo_frame: '_top' } %>
      </div>
    <% end %>
  </div>
<% end %>
```

### New/Edit Views

```erb
<%# app/views/products/new.html.erb %>
<%= render 'form', product: @product %>
```

```erb
<%# app/views/products/edit.html.erb %>
<%= render 'form', product: @product %>
```

## Step 4: Add Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :products
  root 'products#index'
end
```

## How It Works

### Turbo Frames

- The "New Product" and "Edit" links target `turbo_frame: 'modal'`
- Forms render inside the modal frame
- Cancel links break out with `turbo_frame: '_top'`

### Turbo Streams

When creating/updating/deleting:
- Regular browser requests get HTML redirects
- Turbo Stream requests get targeted DOM updates:
  - `prepend` adds new products to the list
  - `replace` updates existing products
  - `remove` deletes products from the DOM
  - `update` refreshes flash messages

### Progressive Enhancement

- Works without JavaScript (full page reloads)
- With Turbo, gets instant updates without page reload

## Using ViewComponents

Replace partials with components for better encapsulation:

```ruby
# app/components/product_row_component.rb
class ProductRowComponent < ViewComponent::Base
  def initialize(product:)
    @product = product
  end
end
```

```erb
<%# app/components/product_row_component.html.erb %>
<%= turbo_frame_tag @product do %>
  <div class="product-card">
    <h3><%= @product.name %></h3>
    <p class="price"><%= number_to_currency(@product.price) %></p>
  </div>
<% end %>
```

Then in the controller:

```ruby
on_success do
  turbo_stream do
    prepend :products_list, component: ProductRowComponent
  end
end
```

## Next Steps

- Add authentication (Devise)
- Add authorization (Pundit)
- Add real-time updates with Action Cable
- Style with Tailwind or Bootstrap
