# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Placeholder implementation for Hotspots analytics per DR-014.
    # Computes a normalized score per file (frequency x size) over selected period.
    class Hotspots
      def self.call(_enum, filters)
        # TODO: implement real hotspots computation. For now, return empty structure.
        {
          report: 'hotspots',
          generated_at: Time.now.utc.iso8601,
          repo_path: File.expand_path(filters.repo_path),
          period: { since: filters.since_iso8601, until: filters.until_iso8601 },
          items: []
        }
      end
    end
  end
end
