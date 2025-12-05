require "bundler/setup"
require "slimak"
require "active_record"
require "logger"

# Configure in-memory sqlite for ActiveRecord integration tests
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(nil)

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Schema.define(version: 1) do
      create_table :tasks, force: true do |t|
        t.string  :name
        t.string  :urgency
        t.string  :assignee_name
        t.string  :slug
        t.integer :project_id
        t.timestamps null: false
      end
      add_index :tasks, :slug
      add_index :tasks, [:project_id, :slug], unique: true
    end

    # define model used in specs
    class Task < ActiveRecord::Base
      include Slimak::Sluggable
      slug_columns :name, :urgency, :assignee_name
    end
  end

  config.before(:each) do
    Task.delete_all
  end
end
