# frozen_string_literal: true

require_relative 'terminal_width'
require_relative 'languages_section'

module PrettyGit
  module Render
    # Simple color helpers used by console components.
    module Colors
      module_function

      def apply(code, text, enabled)
        return text unless enabled

        "\e[#{code}m#{text}\e[0m"
      end

      def title(text, enabled, theme = 'basic')
        code = theme == 'bright' ? '1;35' : '1;36'
        apply(code, text, enabled)
      end

      def header(text, enabled, theme = 'basic')
        code = theme == 'bright' ? '1;36' : '1;34'
        apply(code, text, enabled)
      end

      def dim(text, enabled)
        apply('2;37', text, enabled)
      end

      def green(text, enabled)
        apply('32', text, enabled)
      end

      def red(text, enabled)
        apply('31', text, enabled)
      end

      def yellow(text, enabled)
        apply('33', text, enabled)
      end

      def bold(text, enabled)
        apply('1', text, enabled)
      end
    end

    # Prints aligned ASCII tables with optional colored headers.
    class TablePrinter
      def initialize(io, color: true, theme: 'basic')
        @io = io
        @color = color
        @theme = theme
      end

      def print(headers, rows, highlight_max: true, first_col_colorizer: nil)
        widths = compute_widths(headers, rows)
        if (term_cols = TerminalWidth.detect_terminal_columns(@io))
          widths = TerminalWidth.fit_to_terminal(widths, term_cols)
        end

        print_header(headers, widths)
        print_rows(headers, rows, widths, highlight_max, first_col_colorizer)
        @io.puts 'No data' if rows.empty?
      end

      def compute_widths(headers, rows)
        widths = headers.map(&:length)
        rows.each do |row|
          widths = widths.each_with_index.map do |w, i|
            [w, row[headers[i].to_sym].to_s.length].max
          end
        end
        widths
      end

      # rubocop:disable Metrics/AbcSize
      def print_header(headers, widths)
        header_line = headers.map.with_index do |h, i|
          text = i.zero? ? truncate(h, widths[i]) : h
          i.zero? ? text.ljust(widths[i]) : text.rjust(widths[i])
        end.join(' ')
        sep_line = widths.map { |w| '-' * w }.join(' ')

        @io.puts Colors.header(header_line, @color, @theme)
        @io.puts Colors.dim(sep_line, @color)
      end
      # rubocop:enable Metrics/AbcSize

      def print_rows(headers, rows, widths, highlight_max, first_col_colorizer)
        max_map = highlight_max ? compute_max_map(headers, rows) : {}
        eps = 1e-9
        rows.each do |row|
          cells = []
          headers.each_with_index do |h, i|
            val = row[h.to_sym]
            color_code = i.zero? && first_col_colorizer ? first_col_colorizer.call(row) : nil
            cells << cell_for(
              val,
              widths[i],
              first_col: i.zero?,
              is_max: max_cell?(val, i, max_map, highlight_max, eps),
              color_code: color_code
            )
          end
          @io.puts cells.join(' ')
        end
      end

      def cell_for(value, width, first_col:, is_max: false, color_code: nil)
        raw = value.to_s
        raw = truncate(raw, width) if first_col
        padded = first_col ? raw.ljust(width) : raw.rjust(width)
        return Colors.bold(padded, @color) if is_max
        return Colors.apply(color_code, padded, @color) if first_col && color_code

        padded
      end

      def max_cell?(val, idx, max_map, highlight_max, eps)
        return false unless highlight_max && max_map[idx]
        return false unless numeric?(val)

        (val.to_f - max_map[idx]).abs < eps
      end

      private

      # Terminal width helpers moved to PrettyGit::Render::TerminalWidth

      def truncate(text, max)
        return text if text.length <= max
        return text[0, max] if max <= 1

        "#{text[0, max - 1]}…"
      end

      def numeric?(val)
        val.is_a?(Numeric) || val.to_s.match?(/\A-?\d+(\.\d+)?\z/)
      end

      def compute_max_map(headers, rows)
        map = {}
        headers.each_with_index do |_h, i|
          next if i.zero?

          nums = rows.map { |r| r[headers[i].to_sym] }.select { |v| numeric?(v) }.map(&:to_f)
          map[i] = nums.max if nums.any?
        end
        map
      end
    end

    # Renders human-friendly console output with optional colors.
    class ConsoleRenderer
      def initialize(io: $stdout, color: true, theme: 'basic')
        @io = io
        @color = color
        @theme = theme
        @table = TablePrinter.new(@io, color: @color, theme: @theme)
      end

      def call(report, result, _filters)
        case report
        when 'summary'
          render_summary(result)
        when 'activity'
          render_activity(result)
        when 'authors'
          render_authors(result)
        when 'files'
          render_files(result)
        when 'heatmap'
          render_heatmap(result)
        when 'languages'
          LanguagesSection.render(@io, @table, result, color: @color)
        else
          @io.puts result.inspect
        end
      end

      private

      # rubocop:disable Metrics/AbcSize
      def render_summary(data)
        title "Summary for #{data[:repo_path]}"
        period = "Period: #{data.dig(:period, :since)} .. #{data.dig(:period, :until)}"
        line period
        t = data[:totals]
        commits_s = "commits=#{Colors.yellow(t[:commits], @color)}"
        authors_s = "authors=#{t[:authors]}"
        adds_s = "+#{Colors.green(t[:additions], @color)}"
        dels_s = "-#{Colors.red(t[:deletions], @color)}"
        line "Totals: #{commits_s} #{authors_s} #{adds_s} #{dels_s}"

        @io.puts
        title 'Top Authors'
        @table.print(%w[author commits additions deletions avg_commit_size], data[:top_authors])

        @io.puts
        title 'Top Files'
        @table.print(%w[path commits additions deletions changes], data[:top_files])

        @io.puts
        line "Generated at: #{data[:generated_at]}"
      end
      # rubocop:enable Metrics/AbcSize

      def render_activity(data)
        title "Activity for #{data[:repo_path]}"
        line "Period: #{data.dig(:period, :since)} .. #{data.dig(:period, :until)}"
        line "Bucket: #{data[:bucket]}"

        @io.puts
        title 'Activity'
        @table.print(%w[bucket timestamp commits additions deletions], data[:items])

        @io.puts
        line "Generated at: #{data[:generated_at]}"
      end

      # rubocop:disable Metrics/AbcSize
      def render_authors(data)
        title "Authors for #{data[:repo_path]}"
        line "Period: #{data.dig(:period, :since)} .. #{data.dig(:period, :until)}"
        t = data[:totals]
        commits_s = "commits=#{Colors.yellow(t[:commits], @color)}"
        authors_s = "authors=#{t[:authors]}"
        adds_s = "+#{Colors.green(t[:additions], @color)}"
        dels_s = "-#{Colors.red(t[:deletions], @color)}"
        line "Totals: #{authors_s} #{commits_s} #{adds_s} #{dels_s}"

        @io.puts
        title 'Authors'
        @table.print(%w[author author_email commits additions deletions avg_commit_size], data[:items])

        @io.puts
        line "Generated at: #{data[:generated_at]}"
      end
      # rubocop:enable Metrics/AbcSize

      def render_files(data)
        title "Files for #{data[:repo_path]}"
        line "Period: #{data.dig(:period, :since)} .. #{data.dig(:period, :until)}"

        @io.puts
        title 'Files'
        @table.print(%w[path commits additions deletions changes], data[:items])

        @io.puts
        line "Generated at: #{data[:generated_at]}"
      end

      def render_heatmap(data)
        title "Heatmap for #{data[:repo_path]}"
        line "Period: #{data.dig(:period, :since)} .. #{data.dig(:period, :until)}"

        @io.puts
        title 'Heatmap'
        @table.print(%w[dow hour commits], data[:items])

        @io.puts
        line "Generated at: #{data[:generated_at]}"
      end

      # Languages rendering moved to PrettyGit::Render::LanguagesSection

      def title(text)
        @io.puts Colors.title(text, @color, @theme)
      end

      def line(text)
        @io.puts text
      end

      # table is handled by @table
    end
  end
end
