# frozen_string_literal: true

module PrettyGit
  module Render
    # Renders Markdown tables and sections per specs/output_formats.md
    class MarkdownRenderer
      def initialize(io: $stdout)
        @io = io
      end

      def call(report, result, _filters)
        case report
        when 'summary'
          render_summary(result)
        when 'activity'
          render_table('Activity', %w[bucket timestamp commits additions deletions], result[:items])
        when 'authors'
          render_table('Authors', %w[author author_email commits additions deletions avg_commit_size], result[:items])
        when 'files'
          render_table('Top Files', %w[path commits additions deletions changes], result[:items])
        when 'heatmap'
          render_table('Heatmap', %w[dow hour commits], result[:items])
        when 'languages'
          render_table('Languages', %w[language bytes percent color], result[:items])
        else
          @io.puts result.inspect
        end
      end

      private

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
