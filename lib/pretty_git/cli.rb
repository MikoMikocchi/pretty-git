# frozen_string_literal: true

require 'optparse'
require_relative 'version'
require_relative 'filters'
require_relative 'app'

module PrettyGit
  # Command-line interface entry point.
  class CLI
    SUPPORTED_REPORTS = %w[summary activity authors files heatmap].freeze
    SUPPORTED_FORMATS = %w[console json csv md yaml xml].freeze

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.run(argv = ARGV, out: $stdout, err: $stderr)
      options = {
        report: 'summary',
        repo: '.',
        branches: [],
        authors: [],
        exclude_authors: [],
        paths: [],
        exclude_paths: [],
        time_bucket: 'week',
        limit: 10,
        format: 'console',
        out: nil,
        no_color: false
      }

      parser = OptionParser.new do |opts|
        opts.banner = 'Usage: pretty-git [REPORT] [options]'

        opts.on('--repo PATH', 'Path to git repository (default: .)') { |v| options[:repo] = v }
        opts.on('--branch NAME', 'Branch (repeatable)') { |v| options[:branches] << v }
        opts.on('--since DATETIME', 'Start of period (ISO8601 or YYYY-MM-DD)') { |v| options[:since] = v }
        opts.on('--until DATETIME', 'End of period (inclusive)') { |v| options[:until] = v }
        opts.on('--author VAL', 'Include author (repeatable)') { |v| options[:authors] << v }
        opts.on('--exclude-author VAL', 'Exclude author (repeatable)') { |v| options[:exclude_authors] << v }
        opts.on('--path GLOB', 'Include path/glob (repeatable)') { |v| options[:paths] << v }
        opts.on('--exclude-path GLOB', 'Exclude path/glob (repeatable)') { |v| options[:exclude_paths] << v }
        opts.on('--time-bucket BUCKET', 'day|week|month (for activity)') { |v| options[:time_bucket] = v }
        opts.on('--limit N', Integer, 'Top limit (0/all = unlimited)') { |v| options[:limit] = v }
        opts.on('--format FMT', SUPPORTED_FORMATS, 'console|json|csv|md|yaml|xml') { |v| options[:format] = v }
        opts.on('--out FILE', 'Output file path') { |v| options[:out] = v }
        opts.on('--no-color', 'Disable colors in console output') { options[:no_color] = true }
        opts.on('--version', 'Show version') do
          out.puts PrettyGit::VERSION
          return 0
        end
        opts.on('--help', 'Show help') do
          out.puts opts
          return 0
        end
      end

      # REPORT positional arg
      options[:report] = argv.shift if argv[0] && argv[0] !~ /^-/

      begin
        parser.parse!(argv)
      rescue OptionParser::InvalidOption => e
        err.puts e.message
        err.puts parser
        return 1
      end

      unless SUPPORTED_REPORTS.include?(options[:report])
        err.puts "Unknown report: #{options[:report]}. Supported: #{SUPPORTED_REPORTS.join(', ')}"
        return 1
      end

      filters = Filters.new(
        repo_path: options[:repo],
        branches: options[:branches],
        since: options[:since],
        until: options[:until],
        authors: options[:authors],
        exclude_authors: options[:exclude_authors],
        paths: options[:paths],
        exclude_paths: options[:exclude_paths],
        time_bucket: options[:time_bucket],
        limit: options[:limit],
        format: options[:format],
        out: options[:out],
        no_color: options[:no_color]
      )

      if options[:out]
        File.open(options[:out], 'w') do |f|
          return App.new.run(options[:report], filters, out: f, err: err)
        end
      else
        App.new.run(options[:report], filters, out: out, err: err)
      end
    rescue ArgumentError => e
      err.puts e.message
      1
    rescue StandardError => e
      err.puts e.message
      2
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
