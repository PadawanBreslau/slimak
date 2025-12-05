# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slimak'

Gem::Specification.new do |spec|
  spec.name          = "slimak"
  spec.version       = Slimak::VERSION
  spec.summary       = "Multi-column slugs with ActiveRecord persistence & fast lookup"
  spec.description   = "Slimak creates slugs from multiple model attributes (slug_columns) and supports storing them in the DB with uniqueness and fast lookup."
  spec.authors       = ["Stanislaw Zawadzki"]
  spec.email         = ["st.zawadzki@gmail.com"]
  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE", "Rakefile"]
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  # runtime dependency used for parameterize/transliterate convenience
  spec.add_runtime_dependency "activesupport", ">= 5.2"

  # development / test dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activerecord", "~> 8.0"
  spec.add_development_dependency "sqlite3", ">= 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry"
end
