require 'logger'
require_relative "slimak/version"

# helpers from ActiveSupport for parameterize
require "active_support"
require "active_support/core_ext/string/inflections"
require "active_support/inflector"
require "active_support/concern"

require_relative "slimak/sluggable"
require_relative "slimak/railtie" if defined?(Rails)

module Slimak
end
