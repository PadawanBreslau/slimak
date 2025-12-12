require "securerandom"

module Slimak
  # Sluggable concern for ActiveRecord models (also usable on plain Ruby objects).
  module Sluggable
    extend ActiveSupport::Concern

    included do
      if defined?(ActiveRecord) && self <= ActiveRecord::Base
        before_validation :generate_slug_if_blank
      end
    end

    class_methods do
      def slug_columns(*cols)
        @_slimak_slug_columns = cols.flatten.map(&:to_sym)
        @_slimak_slug_column_limits ||= {}
        @_slimak_slug_options ||= default_slug_options
      end

      def slug_column_limits(hash = nil)
        # Merge global limits with model-specific limits; model-specific wins.
        global = Slimak.config.slug_column_limits || {}
        @_slimak_slug_column_limits ||= global.dup
        if hash
          @_slimak_slug_column_limits.merge!(hash.transform_keys(&:to_sym))
        end
        @_slimak_slug_column_limits
      end

      def slug_options(opts = nil)
        @_slimak_slug_options ||= default_slug_options
        @_slimak_slug_options.merge!(opts) if opts.is_a?(Hash)
        @_slimak_slug_options
      end

      # Default options come from global Slimak.config so users can set global defaults.
      def default_slug_options
        Slimak.config.to_hash
      end

      def _slimak_slug_columns
        @_slimak_slug_columns || []
      end

      def _slimak_slug_column_limits
        @_slimak_slug_column_limits || Slimak.config.slug_column_limits || {}
      end

      def _slimak_slug_options
        @_slimak_slug_options ||= default_slug_options
      end

      def find_by_slug(value)
        col = _slimak_slug_options[:column]
        where(col => value).first
      end

      def find_by_json_slug(value)
        col = _slimak_slug_options[:column]
        
        binding.pry
        #TODO
      end

      def find_by_slug!(value)
        find_by_slug(value) or raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with slug=#{value}"
      end
    end

    def _slug
      col = self.class._slimak_slug_options[:column]
      if respond_to?(col) && !send(col).to_s.strip.empty?
        send(col).to_s
      else
        build_slug_string
      end
    end

    def generate_slug_if_blank
      return unless self.class._slimak_slug_columns.any?

      slug_col = self.class._slimak_slug_options[:column]
      if respond_to?(slug_col) && !send(slug_col).to_s.strip.empty?
        return
      end

      candidate = build_unique_slug
      assign_slug_column(slug_col, candidate)
      nil
    end

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

    def build_unique_slug
      base = build_slug_string
      return base if base.to_s.strip.empty?
      return base unless defined?(ActiveRecord) && self.class.respond_to?(:unscoped)

      # Merge global options with model options so model options override global.
      opts = Slimak.config.to_hash.merge(self.class._slimak_slug_options || {})
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
      else
        candidate = base.dup
        seq = 2
        while slug_exists?(candidate, col, scope)
          candidate = [base, seq].join(opts[:sequence_separator])
          seq += 1
        end
        candidate
      end
    end

    # Safe read helper
    def safe_read(name)
      if respond_to?(name)
        send(name)
      else
        nil
      end
    rescue => _
      nil
    end

    def format_component(str, column)
      s = str.dup
      s = ActiveSupport::Inflector.transliterate(s) if defined?(ActiveSupport::Inflector)
      s = s.strip
      limits = self.class._slimak_slug_column_limits || {}
      max = limits && limits[column.to_sym]
      s = s[0, max] if max && max > 0
      s.gsub(/[[:space:]]+/, " ")
    end

    def assign_slug_column(slug_col, value)
      if respond_to?("#{slug_col}=")
        send("#{slug_col}=", value)
      elsif respond_to?(:write_attribute)
        write_attribute(slug_col, value)
      else
        (class << self; self; end).class_eval do
          attr_accessor slug_col unless method_defined?(slug_col)
        end
        instance_variable_set("@#{slug_col}", value)
      end
    end

    def parameterize(str, separator = "-")
      s = str.to_s
      begin
        s.parameterize(separator: separator)
      rescue ArgumentError
        s.parameterize(separator)
      end
    end

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
