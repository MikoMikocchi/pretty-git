# frozen_string_literal: true

require 'time'
require_relative 'utils/time_utils'

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
      # Accept a single Hash positional argument for backward compatibility
      kwargs = args.first if (kwargs.nil? || kwargs.empty?) && args.length == 1 && args.first.is_a?(Hash)
      kwargs ||= {}

      if kwargs.key?(:until)
        Kernel.warn('[pretty-git] DEPRECATION: Filters initialized with :until. Use :until_at instead.')
        kwargs = kwargs.dup
        kwargs[:until_at] = kwargs.delete(:until)
      end

      # Keyword-init struct: prefer keyword form consistently to keep initialize simple
      super(**kwargs)
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
      super
    end

    def []=(key, value)
      key = :until_at if key == :until
      super
    end

    def since_iso8601
      PrettyGit::Utils::TimeUtils.to_utc_iso8601(since)
    end

    # Keep method name for backwards compatibility across the codebase
    def until_iso8601
      PrettyGit::Utils::TimeUtils.to_utc_iso8601(self[:until_at])
    end
  end
end
