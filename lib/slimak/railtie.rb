# Railtie: auto-include Slimak::Sluggable into ActiveRecord::Base for Rails apps.
if defined?(Rails)
  require "rails/railtie"

  module Slimak
    class Railtie < ::Rails::Railtie
      initializer "slimak.active_record" do
        config.paths.add "lib/generators", eager_load: true
        ActiveSupport.on_load(:active_record) do
          include Slimak::Sluggable
        end
      end
    end
  end
end
