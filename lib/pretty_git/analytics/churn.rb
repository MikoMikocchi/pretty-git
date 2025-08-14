# frozen_string_literal: true

require 'time'

module PrettyGit
  module Analytics
    # Placeholder implementation for Churn analytics per DR-014.
    # Measures file/directory volatility over a rolling window.
    class Churn
      def self.call(_enum, filters)
        # TODO: implement real churn computation. For now, return empty structure.
        {
          report: 'churn',
          generated_at: Time.now.utc.iso8601,
          repo_path: File.expand_path(filters.repo_path),
          period: { since: filters.since_iso8601, until: filters.until_iso8601 },
          window: nil,
          items: []
        }
      end
    end
  end
end
