module Slimak
  # Global configuration object for Slimak.
  # Configure in an initializer or test with:
  # Slimak.configure do |config|
  #   config.separator = "_"
  #   config.conflict_strategy = :random
  #   config.random_suffix_length = 6
  #   config.slug_column_limits = { name: 10 }
  # end
  class Configuration
    attr_accessor :column,
                  :separator,
                  :conflict_strategy,
                  :sequence_separator,
                  :random_suffix_length,
                  :scope,
                  :slug_column_limits

    def initialize
      @column = :slug
      @separator = "-"
      @conflict_strategy = :sequence
      @sequence_separator = "-"
      @random_suffix_length = 4
      @scope = nil
      @slug_column_limits = {}
    end

    # Convert config to a plain hash used by Sluggable defaults
    def to_hash
      {
        column: @column,
        separator: @separator,
        conflict_strategy: @conflict_strategy,
        sequence_separator: @sequence_separator,
        random_suffix_length: @random_suffix_length,
        scope: @scope
      }
    end
  end
end
