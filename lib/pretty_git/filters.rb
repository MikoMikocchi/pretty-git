# frozen_string_literal: true

require 'time'

module PrettyGit
  Filters = Struct.new(
    :repo_path,
    :branches,
    :since,
    :until,
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
    keyword_init: true
  ) do
    def since_iso8601
      time_to_iso8601(since)
    end

    def until_iso8601
      time_to_iso8601(self[:until])
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
