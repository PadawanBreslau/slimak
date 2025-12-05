require 'logger'
require_relative "slimak/version"

# helpers from ActiveSupport for parameterize
require "active_support"
require "active_support/core_ext/string/inflections"
require "active_support/inflector"
require "active_support/concern"

require_relative "slimak/configuration"
require_relative "slimak/sluggable"
require_relative "slimak/railtie" if defined?(Rails)

module Slimak
  # Global config object; you can reassign in tests if necessary
  @config = Configuration.new

  class << self
    # Accessor for global config
    def config
      @config
    end

    # Setter for global config (useful for tests)
    def config=(c)
      @config = c
    end

    # Convenience configure block: Slimak.configure { |c| c.separator = "_" }
    def configure
      yield config if block_given?
      config
    end

    # Reset global config to defaults
    def reset!
      @config = Configuration.new
    end
  end
end
