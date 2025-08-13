# frozen_string_literal: true

require 'csv'

module PrettyGit
  module Render
    # Renders CSV according to specs/output_formats.md and DR-001
    class CsvRenderer
      def initialize(io: $stdout)
        @io = io
      end

      def call(report, result, _filters)
        case report
        when 'activity'
          write_csv(%w[bucket timestamp commits additions deletions], result[:items])
        when 'authors'
          write_csv(%w[author author_email commits additions deletions avg_commit_size], result[:items])
        when 'files'
          write_csv(%w[path commits additions deletions changes], result[:items])
        when 'heatmap'
          write_csv(%w[dow hour commits], result[:items])
        when 'languages'
          metric = (result[:metric] || 'bytes').to_s
          headers = ['language', metric, 'percent', 'color']
          write_csv(headers, result[:items])
        else
          raise ArgumentError, "CSV output for report '#{report}' is not supported yet"
        end
      end

      private

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
