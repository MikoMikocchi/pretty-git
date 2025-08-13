# frozen_string_literal: true

module PrettyGit
  module Render
    # Renders the Languages report table with colorized language names.
    module LanguagesSection
      LANG_ANSI_COLOR_CODES = {
        'Ruby' => '31',
        'JavaScript' => '33', 'TypeScript' => '34',
        'JSX' => '33', 'TSX' => '34',
        'Python' => '34', 'Go' => '36', 'Rust' => '33', 'Java' => '31',
        'C' => '37', 'C++' => '35', 'C#' => '32', 'Objective-C' => '36', 'Swift' => '35',
        'Kotlin' => '35', 'Scala' => '35', 'Groovy' => '32', 'Dart' => '36',
        'PHP' => '35', 'Perl' => '35', 'R' => '35', 'Lua' => '34', 'Haskell' => '35',
        'Elixir' => '35', 'Erlang' => '31',
        'Shell' => '32', 'PowerShell' => '34', 'Batchfile' => '33',
        'HTML' => '31', 'CSS' => '35', 'SCSS' => '35',
        'JSON' => '37', 'YAML' => '31', 'TOML' => '33', 'INI' => '33', 'XML' => '36',
        'Markdown' => '34', 'Makefile' => '33', 'Dockerfile' => '36',
        'SQL' => '36', 'GraphQL' => '35', 'Proto' => '33',
        'Svelte' => '31', 'Vue' => '32'
      }.freeze

      module_function

      def render(io, table, data, color: true)
        title(io, data, color)
        io.puts
        metric = (data[:metric] || 'bytes').to_s
        table_rows = rows(data[:items], metric)
        colorizer = ->(row) { LANG_ANSI_COLOR_CODES[row[:language]] }
        headers = ['language', metric, 'percent']
        table.print(headers, table_rows, highlight_max: false, first_col_colorizer: colorizer)
        io.puts
        io.puts "Generated at: #{data[:generated_at]}"
      end

      def title(io, data, color)
        io.puts Colors.title("Languages for #{data[:repo_path]}", color)
      end

      def rows(items, metric)
        key = metric.to_sym
        items.map do |item|
          { language: item[:language], key => item[key], percent: format('%.2f', item[:percent]) }
        end
      end
    end
  end
end
