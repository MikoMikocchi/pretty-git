# frozen_string_literal: true

require 'time'

module PrettyGit
  Filters = Struct.new(
    :repo_path,
    :branches,
    :since,
    :until_at,
    :authors,
    :exclude_authors,
    :paths,
    :exclude_paths,
    :time_bucket,
    :metric,
    :limit,
    :format,
    :out,
    :no_color,
    :theme,
    :verbose,
    keyword_init: true
  ) do
    # Backward-compat: allow initializing with `until:` keyword by remapping to :until_at
    # Preserve Struct keyword_init behavior by overriding initialize instead of .new
    def initialize(*args, **kwargs)
      # Support calling with a single Hash as positional arg (older call sites)
      if (kwargs.nil? || kwargs.empty?) && args.length == 1 && args.first.is_a?(Hash)
        kwargs = args.first
        args = []
      end

      kwargs ||= {}
      if kwargs.key?(:until)
        kwargs = kwargs.dup
        kwargs[:until_at] = kwargs.delete(:until)
      end

      if kwargs.empty?
        super(*args)
      else
        super(**kwargs)
      end
    end

    # Backward-compat: support filters.until and filters.until=
    def until
      self[:until_at]
    end

    def until=(val)
      self[:until_at] = val
    end

    # Backward-compat for hash-style access used in older specs
    def [](key)
      key = :until_at if key == :until
      super(key)
    end

    def []=(key, value)
      key = :until_at if key == :until
      super(key, value)
    end
    def since_iso8601
      time_to_iso8601(since)
    end

    # Keep method name for backwards compatibility across the codebase
    def until_iso8601
      time_to_iso8601(self[:until_at])
    end

    private

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def time_to_iso8601(val)
      return nil if val.nil? || val.to_s.strip.empty?

      # If value is a date without time, interpret as UTC midnight to avoid
      # timezone-dependent shifts across environments.
      if val.is_a?(String) && val.match?(/^\d{4}-\d{2}-\d{2}$/)
        y, m, d = val.split('-').map(&:to_i)
        t = Time.new(y, m, d, 0, 0, 0, '+00:00')
      else
        # Otherwise parse normally and normalize to UTC.
        t = val.is_a?(Time) ? val : Time.parse(val.to_s)
      end
      t.utc.iso8601
    rescue ArgumentError
      raise ArgumentError, "Invalid datetime: #{val} (expected ISO8601 or YYYY-MM-DD)"
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
