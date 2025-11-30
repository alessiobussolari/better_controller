# Real World Example: Users CRUD

A complete Users management system demonstrating all BetterController features.

---

## Overview

This example shows:
- Full CRUD operations
- Service object integration (BYOS pattern)
- Multiple response formats (HTML, JSON, CSV, Turbo)
- Pagination
- Search and filtering
- Authorization
- Error handling

## Models

```ruby
# app/models/user.rb
class User < ApplicationRecord
  belongs_to :department, optional: true
  has_many :roles, through: :user_roles

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: URI::MailTo::EMAIL_REGEXP

  scope :active, -> { where(active: true) }
  scope :search, ->(q) { where('name ILIKE ? OR email ILIKE ?', "%#{q}%", "%#{q}%") }
end
```

## Service Objects (BYOS)

Using a simple service pattern (you can use Interactor, Trailblazer, etc.):

```ruby
# app/services/users/list_service.rb
module Users
  class ListService
    def self.call(params:, current_user: nil)
      users = User.includes(:department)

      # Apply filters
      users = users.active if params[:active_only]
      users = users.where(department_id: params[:department_id]) if params[:department_id]
      users = users.search(params[:q]) if params[:q].present?

      # Order
      users = users.order(params[:sort] || :name)

      { success: true, collection: users }
    end
  end
end
```

```ruby
# app/services/users/create_service.rb
module Users
  class CreateService
    def self.call(params:, current_user: nil)
      user = User.new(params)

      if user.save
        { success: true, resource: user }
      else
        { success: false, resource: user, errors: user.errors }
      end
    end
  end
end
```

```ruby
# app/services/users/update_service.rb
module Users
  class UpdateService
    def self.call(id:, params:, current_user: nil)
      user = User.find(id)

      if user.update(params)
        { success: true, resource: user }
      else
        { success: false, resource: user, errors: user.errors }
      end
    end
  end
end
```

```ruby
# app/services/users/destroy_service.rb
module Users
  class DestroyService
    def self.call(id:, params: nil, current_user: nil)
      user = User.find(id)
      user.destroy

      { success: true, resource: user }
    end
  end
end
```

## Controller

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  include BetterController
  include BetterController::Utils::Pagination

  before_action :authenticate_user!

  configure_pagination per_page: 25

  # GET /users
  action :index do
    service Users::ListService

    on_success do
      html do
        @users = paginate(@result[:collection])
        render :index
      end

      turbo_stream do
        @users = paginate(@result[:collection])
        replace :users_list, partial: 'users/list', locals: { users: @users }
        update :users_count, partial: 'users/count', locals: { count: @result[:collection].count }
      end

      json do
        users = paginate(@result[:collection])
        respond_with_success(
          users.map { |u| serialize_user(u) },
          meta: pagination_meta(users)
        )
      end

      csv do
        send_csv @result[:collection],
          filename: "users_#{Date.current.iso8601}.csv",
          columns: [:id, :name, :email, :department_name, :active, :created_at],
          headers: {
            id: 'ID',
            name: 'Name',
            email: 'Email',
            department_name: 'Department',
            active: 'Status',
            created_at: 'Created'
          }
      end
    end
  end

  # GET /users/:id
  action :show do
    before { @user = User.find(params[:id]) }

    on_success do
      html { render :show }
      json { respond_with_success(serialize_user(@user)) }
    end

    on_error :not_found do
      html { redirect_to users_path, alert: 'User not found' }
      json { respond_with_error('User not found', status: :not_found) }
    end
  end

  # GET /users/new
  action :new do
    skip_authorization
    before { @user = User.new }

    on_success do
      html { render :new }
    end
  end

  # POST /users
  action :create do
    service Users::CreateService
    params_key :user
    permit :name, :email, :password, :department_id, :active

    before { authorize User }

    on_success do
      html { redirect_to users_path, notice: 'User created successfully!' }

      turbo_stream do
        prepend :users_list, partial: 'users/user_row', locals: { user: @result[:resource] }
        update :users_count, partial: 'users/count', locals: { count: User.count }
        flash type: :notice, message: 'User created successfully!'
        remove :new_user_modal
      end

      json { respond_with_success(serialize_user(@result[:resource]), status: :created) }
    end

    on_error :validation do
      html do
        @user = @result[:resource]
        render :new, status: :unprocessable_entity
      end

      turbo_stream do
        replace :user_form, partial: 'users/form', locals: { user: @result[:resource] }
        form_errors errors: @result[:errors]
      end

      json { respond_with_error(@result[:errors]) }
    end
  end

  # GET /users/:id/edit
  action :edit do
    before do
      @user = User.find(params[:id])
      authorize @user
    end

    on_success do
      html { render :edit }
    end
  end

  # PATCH/PUT /users/:id
  action :update do
    service Users::UpdateService
    params_key :user
    permit :name, :email, :department_id, :active

    before do
      @user = User.find(params[:id])
      authorize @user
    end

    on_success do
      html { redirect_to users_path, notice: 'User updated successfully!' }

      turbo_stream do
        replace @result[:resource], partial: 'users/user_row', locals: { user: @result[:resource] }
        flash type: :notice, message: 'User updated!'
        remove :edit_user_modal
      end

      json { respond_with_success(serialize_user(@result[:resource])) }
    end

    on_error :validation do
      html do
        @user = @result[:resource]
        render :edit, status: :unprocessable_entity
      end

      turbo_stream do
        replace :user_form, partial: 'users/form', locals: { user: @result[:resource] }
        form_errors errors: @result[:errors]
      end

      json { respond_with_error(@result[:errors]) }
    end
  end

  # DELETE /users/:id
  action :destroy do
    service Users::DestroyService

    before do
      @user = User.find(params[:id])
      authorize @user
    end

    on_success do
      html { redirect_to users_path, notice: 'User deleted!' }

      turbo_stream do
        remove @result[:resource]
        update :users_count, partial: 'users/count', locals: { count: User.count }
        flash type: :notice, message: 'User deleted!'
      end

      json { respond_with_success({ id: @result[:resource].id }, meta: { deleted: true }) }
    end
  end

  private

  def serialize_user(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      department: user.department&.name,
      active: user.active,
      created_at: user.created_at.iso8601,
      updated_at: user.updated_at.iso8601
    }
  end
end
```

## Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :users do
    collection do
      get :export  # Optional: dedicated export action
    end
  end
end
```

## Views Structure

```
app/views/users/
├── index.html.erb      # List view
├── show.html.erb       # Detail view
├── new.html.erb        # New form wrapper
├── edit.html.erb       # Edit form wrapper
├── _list.html.erb      # List partial (for Turbo)
├── _user_row.html.erb  # Single user row
├── _form.html.erb      # Form partial
├── _count.html.erb     # Count display
└── _filters.html.erb   # Search/filter form
```

## Key Features Demonstrated

### Multi-Format Responses

Each action handles HTML, Turbo Stream, JSON, and CSV appropriately.

### Service Integration

Using the BYOS pattern - services return `{success:, resource:, collection:, errors:}` hashes.

### Pagination

```ruby
@users = paginate(@result[:collection])
meta: pagination_meta(@users)
```

### Authorization

```ruby
before { authorize @user }
```

### Turbo Updates

```ruby
turbo_stream do
  prepend :users_list, partial: 'users/user_row'
  update :users_count, partial: 'users/count'
  flash type: :notice, message: 'Created!'
end
```

### CSV Export

```ruby
csv do
  send_csv @result[:collection],
    filename: "users_#{Date.current}.csv",
    columns: [:id, :name, :email],
    headers: { id: 'ID', name: 'Name', email: 'Email' }
end
```

## Testing

```ruby
# spec/controllers/users_controller_spec.rb
RSpec.describe UsersController, type: :controller do
  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'returns JSON' do
      get :index, format: :json
      expect(response.content_type).to include('application/json')
    end

    it 'returns CSV' do
      get :index, format: :csv
      expect(response.content_type).to include('text/csv')
    end
  end

  describe 'POST #create' do
    let(:valid_params) { { user: { name: 'Test', email: 'test@example.com' } } }

    it 'creates a user' do
      expect {
        post :create, params: valid_params
      }.to change(User, :count).by(1)
    end

    it 'returns Turbo Stream' do
      post :create, params: valid_params, as: :turbo_stream
      expect(response.content_type).to include('turbo-stream')
    end
  end
end
```

This example demonstrates how BetterController can be used to build a complete, production-ready CRUD interface with minimal boilerplate code.
