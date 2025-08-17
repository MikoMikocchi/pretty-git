# frozen_string_literal: true

require 'time'

module PrettyGit
  module Utils
    # Utilities for time parsing and ISO8601 normalization used by filters.
    module TimeUtils
      module_function

      # Converts various time inputs to ISO8601 in UTC.
      # Accepts Time, String(ISO8601), or String(YYYY-MM-DD) treated as UTC midnight.
      # Returns nil for nil/blank input. Raises ArgumentError for invalid values.
      def to_utc_iso8601(val)
        return nil if val.nil? || val.to_s.strip.empty?

        parse_to_time(val).utc.iso8601
      rescue ArgumentError
        raise ArgumentError, "Invalid datetime: #{val} (expected ISO8601 or YYYY-MM-DD)"
      end

      def parse_to_time(val)
        return val if val.is_a?(Time)
        return parse_date_only(val) if val.is_a?(String) && date_only?(val)

        Time.parse(val.to_s)
      end

      def parse_date_only(str)
        y, m, d = str.split('-').map(&:to_i)
        Time.new(y, m, d, 0, 0, 0, '+00:00')
      end

      def date_only?(str)
        !!(str =~ /^\d{4}-\d{2}-\d{2}$/)
      end
    end
  end
end
