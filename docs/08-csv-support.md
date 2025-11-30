# CSV Support

BetterController provides helpers for generating and downloading CSV files.

---

## Overview

The CsvSupport concern provides `send_csv` and `generate_csv` methods for easy CSV exports. It's automatically included when using `include BetterController`.

## send_csv

Send a CSV file as a download:

```ruby
def export
  @users = User.all
  send_csv @users, filename: 'users.csv'
end
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `collection` | Array | required | Records to export |
| `filename` | String | `'export.csv'` | Download filename |
| `columns` | Array | auto-detect | Columns to include |
| `headers` | Hash | `{}` | Custom header names |

### Examples

```ruby
# Basic export
send_csv @users

# Custom filename
send_csv @users, filename: 'users_export.csv'

# Specific columns
send_csv @users, columns: [:id, :name, :email]

# Custom headers
send_csv @users,
  columns: [:id, :name, :email, :created_at],
  headers: {
    id: 'User ID',
    name: 'Full Name',
    email: 'Email Address',
    created_at: 'Registration Date'
  }
```

## generate_csv

Generate a CSV string without sending:

```ruby
csv_string = generate_csv(@users, columns: [:id, :name])
# Use csv_string for storage, email attachment, etc.
```

### Parameters

Same as `send_csv` except `filename`.

### Example

```ruby
def export_to_storage
  csv_data = generate_csv(@users, columns: [:id, :name, :email])

  # Save to Active Storage
  report = Report.new(name: 'users_export')
  report.file.attach(
    io: StringIO.new(csv_data),
    filename: 'users.csv',
    content_type: 'text/csv'
  )
  report.save
end
```

## Column Auto-Detection

If `columns` is not specified, columns are auto-detected from the first record:

```ruby
# For ActiveRecord models: uses attribute names
@users = User.all
send_csv @users  # Columns: id, name, email, created_at, updated_at, ...

# For hashes: uses hash keys
data = [{ name: 'John', age: 30 }, { name: 'Jane', age: 25 }]
send_csv data  # Columns: name, age
```

## Value Formatting

Values are automatically formatted:

| Type | Format |
|------|--------|
| `Time`, `DateTime` | `YYYY-MM-DD HH:MM:SS` |
| `Date` | `YYYY-MM-DD` |
| `Array` | Comma-separated string |
| `Hash` | JSON string |
| Others | Default `to_s` |

```ruby
# DateTime: 2024-01-15 10:30:00
# Date: 2024-01-15
# Array: "tag1, tag2, tag3"
# Hash: '{"key":"value"}'
```

## Using with Action DSL

Export via the DSL format handlers:

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

Request with `.csv` extension or `Accept: text/csv` header:

```
GET /users.csv
GET /users?format=csv
```

## Custom Export Actions

Create dedicated export actions:

```ruby
class UsersController < ApplicationController
  include BetterController

  def export
    @users = User.includes(:department).where(active: true)

    send_csv @users,
      filename: "users_#{Date.current}.csv",
      columns: [:id, :name, :email, :department_name, :created_at],
      headers: {
        id: 'ID',
        name: 'Name',
        email: 'Email',
        department_name: 'Department',
        created_at: 'Joined'
      }
  end

  private

  # Add virtual column method
  def department_name
    department&.name
  end
end
```

## Working with Associations

Include association data:

```ruby
class UsersController < ApplicationController
  def export
    @users = User.includes(:department, :roles)

    # Create hash collection with association data
    data = @users.map do |user|
      {
        id: user.id,
        name: user.name,
        email: user.email,
        department: user.department&.name,
        roles: user.roles.pluck(:name).join(', '),
        created_at: user.created_at
      }
    end

    send_csv data,
      filename: 'users_full.csv',
      columns: [:id, :name, :email, :department, :roles, :created_at]
  end
end
```

## Large Exports

For large datasets, consider streaming:

```ruby
def export_large
  headers['Content-Type'] = 'text/csv'
  headers['Content-Disposition'] = 'attachment; filename="large_export.csv"'

  response.stream.write CSV.generate_line(['ID', 'Name', 'Email'])

  User.find_each(batch_size: 1000) do |user|
    response.stream.write CSV.generate_line([user.id, user.name, user.email])
  end
ensure
  response.stream.close
end
```

## Complete Example

```ruby
class ReportsController < ApplicationController
  include BetterController

  def users_report
    @users = User.active.includes(:department)

    respond_to do |format|
      format.html { render :users_report }
      format.csv do
        send_csv build_user_report_data,
          filename: "user_report_#{Date.current.iso8601}.csv",
          columns: [:id, :name, :email, :department, :status, :last_login],
          headers: {
            id: 'User ID',
            name: 'Full Name',
            email: 'Email Address',
            department: 'Department',
            status: 'Account Status',
            last_login: 'Last Login Date'
          }
      end
    end
  end

  private

  def build_user_report_data
    @users.map do |user|
      {
        id: user.id,
        name: user.full_name,
        email: user.email,
        department: user.department&.name || 'N/A',
        status: user.active? ? 'Active' : 'Inactive',
        last_login: user.last_login_at&.strftime('%Y-%m-%d')
      }
    end
  end
end
```
