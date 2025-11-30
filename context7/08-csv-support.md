# CSV Support

CSV generation and download helpers.

---

## send_csv

### Basic Usage

```ruby
def export
  @users = User.all
  send_csv @users, filename: 'users.csv'
end
```

--------------------------------

### With Columns

```ruby
send_csv @users, columns: [:id, :name, :email]
```

--------------------------------

### With Headers

```ruby
send_csv @users,
  columns: [:id, :name, :email],
  headers: {
    id: 'User ID',
    name: 'Full Name',
    email: 'Email Address'
  }
```

--------------------------------

### Full Example

```ruby
send_csv @users,
  filename: 'users_export.csv',
  columns: [:id, :name, :email, :created_at],
  headers: {
    id: 'ID',
    name: 'Name',
    email: 'Email',
    created_at: 'Joined'
  }
```

--------------------------------

## generate_csv

### Generate String

```ruby
csv_string = generate_csv(@users, columns: [:id, :name])
```

--------------------------------

### Store CSV

```ruby
csv_data = generate_csv(@users)

report.file.attach(
  io: StringIO.new(csv_data),
  filename: 'users.csv',
  content_type: 'text/csv'
)
```

--------------------------------

## Action DSL Integration

### CSV Format Handler

```ruby
action :index do
  service Users::IndexService

  on_success do
    html { render_page }
    json { render json: @result }
    csv { send_csv @result[:collection], filename: 'users.csv' }
  end
end
```

--------------------------------

## Column Auto-Detection

### ActiveRecord Models

```ruby
@users = User.all
send_csv @users  # Uses attribute names
```

--------------------------------

### Hashes

```ruby
data = [{ name: 'John', age: 30 }]
send_csv data  # Uses hash keys
```

--------------------------------

## Value Formatting

### Automatic Formatting

```ruby
# DateTime => 'YYYY-MM-DD HH:MM:SS'
# Date => 'YYYY-MM-DD'
# Array => 'item1, item2, item3'
# Hash => '{"key":"value"}'
```

--------------------------------

## Association Data

### Include Associations

```ruby
def export
  @users = User.includes(:department)

  data = @users.map do |user|
    {
      id: user.id,
      name: user.name,
      department: user.department&.name
    }
  end

  send_csv data, columns: [:id, :name, :department]
end
```

--------------------------------

## Request CSV Format

### URL Extension

```
GET /users.csv
```

--------------------------------

### Format Parameter

```
GET /users?format=csv
```

--------------------------------

### Accept Header

```
Accept: text/csv
```

--------------------------------

## Complete Example

### Export Action

```ruby
class UsersController < ApplicationController
  include BetterController

  def export
    @users = User.active.includes(:department)

    send_csv build_export_data,
      filename: "users_#{Date.current}.csv",
      columns: [:id, :name, :email, :department, :status],
      headers: {
        id: 'ID',
        name: 'Full Name',
        email: 'Email',
        department: 'Department',
        status: 'Status'
      }
  end

  private

  def build_export_data
    @users.map do |user|
      {
        id: user.id,
        name: user.full_name,
        email: user.email,
        department: user.department&.name,
        status: user.active? ? 'Active' : 'Inactive'
      }
    end
  end
end
```

--------------------------------
