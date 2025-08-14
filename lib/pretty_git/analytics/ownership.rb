# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Placeholder implementation for Ownership analytics per DR-015.
    # Approximates ownership shares by authors based on commits/lines changed.
    class Ownership
      def self.call(_enum, filters)
        # TODO: implement ownership computation using diff stats aggregation.
        {
          report: 'ownership',
          generated_at: Time.now.utc.iso8601,
          repo_path: File.expand_path(filters.repo_path),
          period: { since: filters.since_iso8601, until: filters.until_iso8601 },
          items: []
        }
      end
    end
  end
end
