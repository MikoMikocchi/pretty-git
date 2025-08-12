# frozen_string_literal: true

require 'optparse'
require_relative 'version'
require_relative 'filters'
require_relative 'app'
require_relative 'cli_helpers'

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
        no_color: false,
        _version: false,
        _help: false
      }

      parser = OptionParser.new
      CLIHelpers.configure_parser(parser, options)

      # REPORT positional arg
      options[:report] = argv.shift if argv[0] && argv[0] !~ /^-/

      begin
        parser.parse!(argv)
      rescue OptionParser::InvalidOption => e
        err.puts e.message
        err.puts parser
        return 1
      end

      exit_code = CLIHelpers.validate_and_maybe_exit(options, parser, out, err)
      return exit_code if exit_code

      filters = CLIHelpers.build_filters(options)
      CLIHelpers.execute(options[:report], filters, options, out, err)
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
