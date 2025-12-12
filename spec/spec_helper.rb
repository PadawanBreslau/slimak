require "bundler/setup"
require "slimak"
require "active_record"
require "logger"


# Configure in-memory sqlite for ActiveRecord integration tests
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(nil)

def run_generator_with_args(args = ['TestApp'], options = {})
  generator = described_class.new(args, options)
  # ensure files are written into our tmp destination
  generator.destination_root = dest
  generator.invoke_all
  generator
end

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

      create_table :translated_tasks, force: true do |t|
        t.string  :name
        t.string  :urgency
        t.string  :assignee_name
        t.json  :slug
        t.integer :project_id
        t.timestamps null: false
      end
      add_index :translated_tasks, :slug, using: :gin
      add_index :translated_tasks, [:project_id, :slug], unique: true
    end

    # define model used in specs
    class Task < ActiveRecord::Base
      include Slimak::Sluggable
      slug_columns :name, :urgency, :assignee_name
    end

    class TranslatedTask < ActiveRecord::Base
      include Slimak::Sluggable
      slug_columns :name
    end
  end

  config.before(:each) do
    Task.delete_all
    TranslatedTask.delete_all
  end
end
