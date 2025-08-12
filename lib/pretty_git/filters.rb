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
    :limit,
    :format,
    :out,
    :no_color,
    keyword_init: true
  ) do
    def since_iso8601
      time_to_iso8601(since)
    end

    def until_iso8601
      time_to_iso8601(self[:until])
    end

    private

    def time_to_iso8601(val)
      return nil if val.nil? || val.to_s.strip.empty?
      t = val.is_a?(Time) ? val : Time.parse(val.to_s)
      t = t.getlocal if t.utc_offset.nil?
      t.utc.iso8601
    rescue ArgumentError
      raise ArgumentError, "Invalid datetime: #{val} (expected ISO8601 or YYYY-MM-DD)"
    end
  end
end
