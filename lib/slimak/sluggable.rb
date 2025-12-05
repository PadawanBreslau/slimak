require "securerandom"

module Slimak
  # Sluggable concern for ActiveRecord models (also usable on plain Ruby objects,
  # but uniqueness/finders are AR-specific).
  module Sluggable
    extend ActiveSupport::Concern

    included do
      # If included into ActiveRecord models, generate slug before validation when blank
      if defined?(ActiveRecord) && self <= ActiveRecord::Base
        before_validation :generate_slug_if_blank
      end
    end

    class_methods do
      # Configure which attributes are used to build a slug:
      #   slug_columns :name, :assignee_name, :urgency
      def slug_columns(*cols)
        @_slimak_slug_columns = cols.flatten.map(&:to_sym)
        @_slimak_slug_column_limits ||= {}
        @_slimak_slug_options ||= default_slug_options
      end

      # Per-column character limits (hash). Example: slug_column_limits name: 10
      def slug_column_limits(hash = nil)
        @_slimak_slug_column_limits ||= {}
        @_slimak_slug_column_limits.merge!(hash.transform_keys(&:to_sym)) if hash
        @_slimak_slug_column_limits
      end

      # Configure options (merge into defaults)
      # Options:
      #   column: symbol (default :slug)
      #   separator: string (default "-")
      #   conflict_strategy: :sequence | :random (default :sequence)
      #   sequence_separator: string appended before sequence (default "-")
      #   random_suffix_length: integer (default 4)
      #   scope: symbol or array of symbols to scope uniqueness
      def slug_options(opts = nil)
        @_slimak_slug_options ||= default_slug_options
        @_slimak_slug_options.merge!(opts) if opts.is_a?(Hash)
        @_slimak_slug_options
      end

      def default_slug_options
        {
          column: :slug,
          separator: "-",
          conflict_strategy: :sequence,
          sequence_separator: "-",
          random_suffix_length: 4,
          scope: nil
        }
      end

      def _slimak_slug_columns
        @_slimak_slug_columns || []
      end

      def _slimak_slug_column_limits
        @_slimak_slug_column_limits || {}
      end

      def _slimak_slug_options
        @_slimak_slug_options ||= default_slug_options
      end

      # AR finder helpers (use configured column)
      def find_by_slug(value)
        col = _slimak_slug_options[:column]
        where(col => value).first
      end

      def find_by_slug!(value)
        find_by_slug(value) or raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with slug=#{value}"
      end
    end

    # instance methods
    def _slug
      col = self.class._slimak_slug_options[:column]
      
      if respond_to?(col) && !send(col).to_s.strip.empty?
        send(col).to_s
      else
        build_slug_string
      end
    end

    # called before_validation (ActiveRecord) to persist slug if blank
    def generate_slug_if_blank
      return unless self.class._slimak_slug_columns.any?

      slug_col = self.class._slimak_slug_options[:column]
      # don't overwrite explicitly set slug
      if respond_to?(slug_col) && !send(slug_col).to_s.strip.empty?
        return
      end

      candidate = build_unique_slug
      assign_slug_column(slug_col, candidate)
      nil
    end

    # build slug (non-unique) from configured columns
    def build_slug_string
      parts = self.class._slimak_slug_columns.map do |col|
        v = safe_read(col)
        next nil if v.nil?
        formatted = format_component(v.to_s, col)
        formatted unless formatted.to_s.empty?
      end.compact

      return "" if parts.empty?

      parameterize(parts.join(" "), self.class._slimak_slug_options[:separator])
    end

    # build a unique slug using configured conflict strategy
    def build_unique_slug
      base = build_slug_string
      return base if base.to_s.strip.empty?
      return base unless defined?(ActiveRecord) && self.class.respond_to?(:unscoped)

      opts = self.class._slimak_slug_options
      col = opts[:column]
      scope = opts[:scope]

      case opts[:conflict_strategy].to_sym
      when :random
        candidate = base.dup
        while slug_exists?(candidate, col, scope)
          suffix = SecureRandom.alphanumeric(opts[:random_suffix_length]).downcase
          candidate = [base, suffix].join(opts[:sequence_separator])
        end
        candidate
      else # :sequence
        candidate = base.dup
        seq = 2
        while slug_exists?(candidate, col, scope)
          candidate = [base, seq].join(opts[:sequence_separator])
          seq += 1
        end
        candidate
      end
    end

    private

    # read attribute safely (handles missing methods)
    def safe_read(name)
      if respond_to?(name)
        send(name)
      else
        nil
      end
    rescue => _
      nil
    end

    # format component: transliterate, strip, truncate by per-column limits
    def format_component(str, column)
      s = str.dup
      s = ActiveSupport::Inflector.transliterate(s) if defined?(ActiveSupport::Inflector)
      s = s.strip
      limits = self.class._slimak_slug_column_limits
      max = limits && limits[column.to_sym]
      s = s[0, max] if max && max > 0
      # collapse whitespace to single space; punctuation left for parameterize
      s.gsub(/[[:space:]]+/, " ")
    end

    # assign slug into the configured column (works for AR or plain ruby objects)
    def assign_slug_column(slug_col, value)
      if respond_to?("#{slug_col}=")
        send("#{slug_col}=", value)
      elsif respond_to?(:write_attribute)
        write_attribute(slug_col, value)
      else
        # fallback: define accessor on singleton class and set ivar
        (class << self; self; end).class_eval do
          attr_accessor slug_col unless method_defined?(slug_col)
        end
        instance_variable_set("@#{slug_col}", value)
      end
    end

    # parameterize with ActiveSupport fallback already present
    def parameterize(str, separator = "-")
      s = str.to_s
      begin
        s.parameterize(separator: separator)
      rescue ArgumentError
        # older activesupport APIs
        s.parameterize(separator)
      end
    end

    # check existence in DB (honoring optional scope); excludes self if persisted
    def slug_exists?(candidate, col, scope)
      return false unless defined?(ActiveRecord) && self.class.respond_to?(:unscoped)
      rel = self.class.unscoped.where(col => candidate)
      if scope
        Array(scope).each do |sc|
          val = safe_read(sc)
          rel = rel.where(sc => val)
        end
      end
      if respond_to?(:persisted?) && persisted?
        rel = rel.where.not(id: id)
      end
      rel.exists?
    end
  end
end
