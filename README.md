```markdown
# Slimak

Slimak generates slugs from multiple attributes (columns) and helps persist them to the database with uniqueness and fast lookup.

Features
- Configure which columns to include in a slug: `slug_columns :name, :assignee_name, :urgency`
- Returns readable, parameterized slugs (uses ActiveSupport if available)
- Optionally persists slug to a DB column (default :slug)
- Ensures uniqueness by appending a numeric suffix when needed (e.g., `paint-the-wall`, `paint-the-wall-2`)
- Fast lookup via `Model.find_by_slug("...")` and optional DB index/unique constraint
- Rails Railtie automatically includes into ActiveRecord models

Installation
Add to your Gemfile:

```ruby
gem "slimak"
```

Usage (ActiveRecord)
1) Add a slug column and index to your model's table:

```ruby
class AddSlugToTasks < ActiveRecord::Migration[6.0]
  def change
    add_column :tasks, :slug, :string
    add_index  :tasks, :slug, unique: true
    # If you scope uniqueness (e.g., per project):
    # add_index :tasks, [:project_id, :slug], unique: true
  end
end
```

2) Configure the model:

```ruby
class Task < ApplicationRecord
  include Slimak::Sluggable # is auto-included by Railtie, but explicit include is fine
  slug_columns :name, :urgency, :assignee_name
  # optional:
  # slug_options column: :permalink
  # slug_options scope: :project_id
end
```

By default, a slug will be generated and saved before validation if the slug column is blank. If a generated slug collides with an existing record, a numeric suffix will be appended (e.g., -2, -3) until uniqueness is achieved.

3) Finding by slug:

```ruby
Task.find_by_slug("paint-the-wall-2")
# or
Task.find_by_slug!("paint-the-wall")
```

Usage (Plain Ruby object)
```ruby
class FakeTask
  include Slimak::Sluggable
  attr_accessor :name, :urgency, :assignee_name
  slug_columns :name, :urgency, :assignee_name
end

t = FakeTask.new
t.name = "Paint the wall"
t.urgency = "Critical"
t.assignee_name = "Mark"
t.slug # => "paint-the-wall-critical-mark"
```

Generators
```ruby
rails generate slimak:add_slug ModelName 

Options: --column=NAME Column to add/store slug (default: slug) --scope=COLUMN_NAME Optional scope column (creates composite unique index)
```


Notes & Next steps
- For robust concurrency-safe uniqueness you should also enforce a UNIQUE index in the database and handle possible race conditions (e.g., retry on unique constraint violation). Slimak already appends numeric suffixes to avoid collisions, but an index prevents races.
- You can scope uniqueness via `slug_options scope: :project_id` and add a composite unique index [project_id, slug].
- If you'd like, I can add a Rails generator to create migrations, or implement a DB-retry strategy to handle high concurrency collisions.

```
