# frozen_string_literal: true

module PrettyGit
  module Render
    # Renders human-friendly console output with optional colors.
    class ConsoleRenderer
      def initialize(io: $stdout, color: true)
        @io = io
        @color = color
      end

      def call(report, result, _filters)
        case report
        when 'summary'
          render_summary(result)
        else
          @io.puts result.inspect
        end
      end

      private

      # rubocop:disable Metrics/AbcSize
      def render_summary(data)
        title "Summary for #{data[:repo_path]}"
        line "Period: #{data.dig(:period, :since)} .. #{data.dig(:period, :until)}"
        t = data[:totals]
        line "Totals: commits=#{t[:commits]} authors=#{t[:authors]} +#{t[:additions]} -#{t[:deletions]}"

        @io.puts
        title 'Top Authors'
        table(%w[author commits additions deletions avg_commit_size], data[:top_authors])

        @io.puts
        title 'Top Files'
        table(%w[path commits additions deletions changes], data[:top_files])

        @io.puts
        line "Generated at: #{data[:generated_at]}"
      end
      # rubocop:enable Metrics/AbcSize

      def title(text)
        if @color
          @io.puts "\e[1;36m#{text}\e[0m"
        else
          @io.puts text
        end
      end

      def line(text)
        @io.puts text
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def table(headers, rows)
        widths = headers.map(&:length)
        rows.each do |r|
          widths = widths.each_with_index.map { |w, i| [w, r[headers[i].to_sym].to_s.length].max }
        end

        fmt = widths.map.with_index { |w, i| i.zero? ? "%-#{w}s" : " %#{w}s" }.join
        @io.puts headers.map.with_index { |h, i| (i.zero? ? h.ljust(widths[i]) : h.rjust(widths[i])) }.join(' ')
        @io.puts widths.map { |w| '-' * w }.join(' ')
        rows.each do |r|
          vals = headers.map { |h| r[h.to_sym] }
          @io.puts format(fmt, *vals)
        end
        @io.puts 'No data' if rows.empty?
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
