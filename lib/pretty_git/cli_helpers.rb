# frozen_string_literal: true

require 'optparse'
require_relative 'filters'
require_relative 'app'

module PrettyGit
  # Helpers extracted from `PrettyGit::CLI` to keep the CLI class small
  # and RuboCop-compliant. Provides parser configuration and execution utilities.
  module CLIHelpers
    REPORTS = %w[summary activity authors files heatmap languages].freeze
    FORMATS = %w[console json csv md yaml xml].freeze

    module_function

    def configure_parser(opts, options)
      opts.banner = 'Usage: pretty-git [REPORT] [options]'
      add_repo_options(opts, options)
      add_time_author_options(opts, options)
      add_path_limit_options(opts, options)
      add_format_output_options(opts, options)
      add_misc_options(opts, options)
    end

    def add_repo_options(opts, options)
      opts.on('--repo PATH', 'Path to git repository (default: .)') { |val| options[:repo] = val }
      opts.on('--branch NAME', 'Branch (repeatable)') { |val| options[:branches] << val }
    end

    def add_time_author_options(opts, options)
      opts.on('--since DATETIME', 'Start of period (ISO8601 or YYYY-MM-DD)') { |val| options[:since] = val }
      opts.on('--until DATETIME', 'End of period (inclusive)') { |val| options[:until] = val }
      opts.on('--author VAL', 'Include author (repeatable)') { |val| options[:authors] << val }
      opts.on('--exclude-author VAL', 'Exclude author (repeatable)') { |val| options[:exclude_authors] << val }
      opts.on('--time-bucket BUCKET', 'day|week|month (for activity)') { |val| options[:time_bucket] = val }
    end

    def add_path_limit_options(opts, options)
      opts.on('--path GLOB', 'Include path/glob (repeatable)') { |val| options[:paths] << val }
      opts.on('--exclude-path GLOB', 'Exclude path/glob (repeatable)') { |val| options[:exclude_paths] << val }
      opts.on('--limit N', 'Top limit (0/all = unlimited)') { |val| options[:limit] = parse_limit(val) }
    end

    def add_format_output_options(opts, options)
      opts.on('--format FMT', 'console|json|csv|md|yaml|xml') { |val| options[:format] = val }
      opts.on('--out FILE', 'Output file path') { |val| options[:out] = val }
      opts.on('--no-color', 'Disable colors in console output') { options[:no_color] = true }
      opts.on('--theme NAME', 'console color theme: basic|bright|mono') { |val| options[:theme] = val }
    end

    def add_misc_options(opts, options)
      opts.on('--version', 'Show version') { options[:_version] = true }
      opts.on('--help', 'Show help') { options[:_help] = true }
    end

    def parse_limit(str)
      s = str.to_s.strip
      return 0 if s.casecmp('all').zero?

      Integer(s)
    rescue ArgumentError
      raise ArgumentError, "Invalid --limit: expected integer or 'all'"
    end

    def validate_and_maybe_exit(options, parser, out, err)
      code = handle_version_help(options, parser, out)
      return code unless code.nil?

      return nil if valid_report?(options[:report]) && valid_theme?(options[:theme])

      print_validation_errors(options, err)
      1
    end

    def handle_version_help(options, parser, out)
      if options[:_version]
        out.puts PrettyGit::VERSION
        return 0
      end
      if options[:_help]
        out.puts parser
        return 0
      end
      nil
    end

    def valid_report?(report) = REPORTS.include?(report)
    def valid_theme?(theme) = %w[basic bright mono].include?(theme)

    def print_validation_errors(options, err)
      supported = REPORTS.join(', ')
      unless valid_report?(options[:report])
        err.puts "Unknown report: #{options[:report]}."
        err.puts "Supported: #{supported}"
      end
      return if valid_theme?(options[:theme])

      err.puts "Unknown theme: #{options[:theme]}. Supported: basic, bright, mono"
    end

    def build_filters(options)
      Filters.new(
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
        no_color: options[:no_color],
        theme: options[:theme]
      )
    end

    def execute(report, filters, options, out, err)
      if options[:out]
        File.open(options[:out], 'w') do |f|
          return PrettyGit::App.new.run(report, filters, out: f, err: err)
        end
      end

      PrettyGit::App.new.run(report, filters, out: out, err: err)
    end
  end
end
