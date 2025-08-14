# frozen_string_literal: true

module PrettyGit
  module Render
    # Renders Markdown tables and sections per docs/output_formats.md
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
        rows = sort_rows(report, result[:items], result)
        render_table(title, headers, rows)
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

      # Deterministic ordering per docs/determinism.md
      def sort_rows(report, rows, ctx = nil)
        return rows unless rows.is_a?(Array)

        case report
        when 'hotspots'
          rows.sort_by { |r| [-to_f(r[:score]), -to_i(r[:commits]), -to_i(r[:changes]), to_s(r[:path])] }
        when 'churn'
          rows.sort_by { |r| [-to_i(r[:churn]), -to_i(r[:commits]), to_s(r[:path])] }
        when 'ownership'
          rows.sort_by { |r| [-to_f(r[:owner_share]), -to_i(r[:authors]), to_s(r[:path])] }
        when 'files'
          rows.sort_by { |r| [-to_i(r[:changes]), -to_i(r[:commits]), to_s(r[:path])] }
        when 'authors'
          rows.sort_by { |r| [-to_i(r[:commits]), -to_i(r[:additions]), -to_i(r[:deletions]), to_s(r[:author_email])] }
        when 'languages'
          metric = (ctx && ctx[:metric]) ? ctx[:metric].to_sym : :bytes
          rows.sort_by { |r| [-to_i(r[metric]), to_s(r[:language])] }
        when 'activity'
          rows.sort_by { |r| [to_s(r[:timestamp])] }
        when 'heatmap'
          rows.sort_by { |r| [to_i(r[:dow] || r[:day] || r[:weekday]), to_i(r[:hour])] }
        else
          rows
        end
      end

      def to_i(v)
        Integer(v || 0)
      rescue StandardError
        0
      end

      def to_f(v)
        Float(v || 0.0)
      rescue StandardError
        0.0
      end

      def to_s(v)
        (v || '').to_s
      end
    end
  end
end
