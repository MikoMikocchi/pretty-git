# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require_relative 'filters'
require_relative 'app'
require_relative 'constants'

module PrettyGit
  # Helpers extracted from `PrettyGit::CLI` to keep the CLI class small
  # and RuboCop-compliant. Provides parser configuration and execution utilities.
  # rubocop:disable Metrics/ModuleLength
  module CLIHelpers
    REPORTS = PrettyGit::Constants::REPORTS
    FORMATS = PrettyGit::Constants::FORMATS
    METRICS = PrettyGit::Constants::METRICS
    THEMES  = PrettyGit::Constants::THEMES

    module_function

    def configure_parser(opts, options)
      opts.banner = 'Usage: pretty-git [REPORT] [REPO] [options]'
      add_repo_options(opts, options)
      add_time_author_options(opts, options)
      add_path_limit_options(opts, options)
      add_format_output_options(opts, options)
      add_metric_options(opts, options)
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

    def add_metric_options(opts, options)
      opts.on('--metric NAME', 'languages metric: bytes|files|loc (default: bytes)') do |val|
        options[:metric] = val
      end
    end

    def add_misc_options(opts, options)
      opts.on('--version', 'Show version') { options[:_version] = true }
      opts.on('--help', 'Show help') { options[:_help] = true }
      opts.on('--verbose', 'Verbose output (debug)') { options[:_verbose] = true }
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

      base_ok = valid_base?(options)
      conflicts_ok = validate_conflicts(options, err)
      if base_ok && conflicts_ok
        warn_ignores(options, err)
        return nil
      end

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
    def valid_theme?(theme) = THEMES.include?(theme)
    def valid_format?(fmt) = FORMATS.include?(fmt)

    def valid_base?(options)
      valid_report?(options[:report]) &&
        valid_theme?(options[:theme]) &&
        valid_metric?(options[:metric]) &&
        valid_format?(options[:format])
    end

    def valid_metric?(metric)
      metric.nil? || METRICS.include?(metric)
    end

    def print_validation_errors(options, err)
      print_report_error(options, err)
      print_theme_error(options, err)
      print_format_error(options, err)
      print_metric_error(options, err)
    end

    def print_report_error(options, err)
      return if valid_report?(options[:report])

      err.puts "Unknown report: #{options[:report]}."
      err.puts "Supported: #{REPORTS.join(', ')}"
    end

    def print_theme_error(options, err)
      return if valid_theme?(options[:theme])

      err.puts "Unknown theme: #{options[:theme]}. Supported: #{THEMES.join(', ')}"
    end

    def print_format_error(options, err)
      return if valid_format?(options[:format])

      err.puts "Unknown format: #{options[:format]}. Supported: #{FORMATS.join(', ')}"
    end

    def print_metric_error(options, err)
      return if valid_metric?(options[:metric])

      err.puts "Unknown metric: #{options[:metric]}. Supported: #{METRICS.join(', ')}"
    end

    # Returns true when flags are consistent; otherwise prints errors and returns false
    def validate_conflicts(options, err)
      ok = true
      if options[:metric] && options[:report] != 'languages'
        err.puts "--metric is only supported for 'languages' report"
        ok = false
      end
      # time_bucket is accepted by multiple reports historically; do not enforce here.
      ok
    end

    # Print non-fatal warnings for flags that won't have effect with current options
    def warn_ignores(options, err)
      return unless err

      fmt = options[:format]
      if fmt && fmt != 'console'
        if options[:theme]
          err.puts "Warning: --theme has no effect when --format=#{fmt}"
        end
        if options[:no_color]
          err.puts "Warning: --no-color has no effect when --format=#{fmt}"
        end
      end
    end

    def build_filters(options)
      Filters.new(
        repo_path: options[:repo],
        branches: options[:branches],
        since: options[:since],
        until_at: options[:until],
        authors: options[:authors],
        exclude_authors: options[:exclude_authors],
        paths: options[:paths],
        exclude_paths: options[:exclude_paths],
        time_bucket: options[:time_bucket],
        metric: options[:metric],
        limit: options[:limit],
        format: options[:format],
        out: options[:out],
        no_color: options[:no_color],
        theme: options[:theme],
        verbose: options[:_verbose]
      )
    end

    def execute(report, filters, options, out, err)
      if options[:out]
        begin
          dir = File.dirname(options[:out])
          FileUtils.mkdir_p(dir) unless dir.nil? || dir == '.'
          File.open(options[:out], 'w') do |f|
            return PrettyGit::App.new.run(report, filters, out: f, err: err)
          end
        rescue Errno::EACCES
          err.puts "Cannot write to: #{options[:out]} (permission denied)"
          return 2
        rescue Errno::ENOENT
          err.puts "Cannot write to: #{options[:out]} (directory not found)"
          return 2
        end
      end

      PrettyGit::App.new.run(report, filters, out: out, err: err)
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
