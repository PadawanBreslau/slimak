require "rails/generators"
require "rails/generators/migration"

module Slimak
  module Generators
    # Usage:
    #   rails generate slimak:add_slug ModelName --column=slug --scope=project_id --migration_version=6.1
    class AddSlugGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :column, type: :string, default: "slug", desc: "Column name to store slug"
      class_option :scope, type: :string, default: nil, desc: "Optional scope column name for scoped uniqueness"
      class_option :migration_version, type: :string, default: nil, desc: "Rails migration version to use (e.g. 6.0). Defaults to current."

      # Required by Rails::Generators::Migration to generate unique migration numbers
      def self.next_migration_number(dirname)
        if ActiveRecord.timestamped_migrations
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      def create_migration_file
        migration_filename = "add_#{options['column'] || 'slug'}_to_#{file_name.pluralize}.rb"
        migration_template "add_slug_migration.rb.erb", "db/migrate/#{migration_filename}", migration_version: migration_version_option
      end

      def create_initializer_file
        template "slimak_initializer.rb.erb", "config/initializers/slimak.rb"
      end

      private

      # prefer provided migration_version option; otherwise infer "6.0" if Rails version not available
      def migration_version_option
        return options["migration_version"] if options["migration_version"].present?
        rails_major = if defined?(Rails) && Rails.respond_to?(:version)
                        Rails.version.split(".").first(2).join(".")
                      else
                        "6.0"
                      end
        rails_major
      end

      # helper for templates
      def column_name
        options["column"] || "slug"
      end

      def scope_name
        options["scope"]
      end
    end
  end
end
