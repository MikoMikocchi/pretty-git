# frozen_string_literal: true

require 'csv'

module PrettyGit
  module Render
    # Renders CSV according to docs/output_formats.md and DR-001
    class CsvRenderer
      HEADERS = {
        'activity' => %w[bucket timestamp commits additions deletions],
        'authors' => %w[author author_email commits additions deletions avg_commit_size],
        'files' => %w[path commits additions deletions changes],
        'heatmap' => %w[dow hour commits],
        'hotspots' => %w[path score commits additions deletions changes],
        'churn' => %w[path churn commits additions deletions],
        'ownership' => %w[path owner owner_share authors]
      }.freeze
      def initialize(io: $stdout)
        @io = io
      end

      def call(report, result, _filters)
        headers = headers_for(report, result)
        write_csv(headers, result[:items])
      end

      private

      def headers_for(report, result)
        return ['language', (result[:metric] || 'bytes').to_s, 'percent', 'color'] if report == 'languages'

        HEADERS.fetch(report) do
          raise ArgumentError, "CSV output for report '#{report}' is not supported yet"
        end
      end

      def write_csv(headers, rows)
        csv = CSV.generate(force_quotes: false) do |out|
          out << headers
          rows.each do |row|
            out << headers.map { |h| row[h.to_sym] }
          end
        end
        # Ensure UTF-8 per DR-001
        @io.write(csv.encode('UTF-8'))
      end
    end
  end
end
