# frozen_string_literal: true

module PrettyGit
  module Render
    # Renders Markdown tables and sections per specs/output_formats.md
    class MarkdownRenderer
      TITLES = {
        'activity' => 'Activity',
        'authors' => 'Authors',
        'files' => 'Top Files',
        'heatmap' => 'Heatmap',
        'languages' => 'Languages',
        'hotspots' => 'Hotspots',
        'churn' => 'Churn',
        'ownership' => 'Ownership'
      }.freeze

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
        return render_summary(result) if report == 'summary'

        headers = headers_for(report, result)
        title = title_for(report)
        render_table(title, headers, result[:items])
      end

      private

      def headers_for(report, result)
        return ['language', (result[:metric] || 'bytes').to_s, 'percent', 'color'] if report == 'languages'

        HEADERS.fetch(report, [])
      end

      def title_for(report)
        TITLES.fetch(report, report.to_s.capitalize)
      end

      def render_summary(data)
        header_summary(data)
        print_totals(data[:totals])
        @io.puts
        render_table('Top Authors', %w[author commits additions deletions avg_commit_size], data[:top_authors])
        @io.puts
        render_table('Top Files', %w[path commits additions deletions changes], data[:top_files])
        @io.puts
        @io.puts "Generated at: #{data[:generated_at]}"
      end

      def header_summary(data)
        @io.puts "# Summary for #{data[:repo_path]}"
        @io.puts
        @io.puts "Period: #{data.dig(:period, :since)} .. #{data.dig(:period, :until)}"
      end

      def print_totals(totals)
        @io.puts(
          "Totals: commits=#{totals[:commits]} authors=#{totals[:authors]} " \
          "+#{totals[:additions]} -#{totals[:deletions]}"
        )
      end

      def render_table(title, headers, rows)
        @io.puts "# #{title}"
        @io.puts
        @io.puts "| #{headers.join(' | ')} |"
        @io.puts "|#{headers.map { '---' }.join('|')}|"
        rows.each do |r|
          @io.puts "| #{headers.map { |h| r[h.to_sym] }.join(' | ')} |"
        end
        @io.puts 'No data' if rows.empty?
      end
    end
  end
end
