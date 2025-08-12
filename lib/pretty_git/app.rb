# frozen_string_literal: true

require_relative 'git/provider'
require_relative 'analytics/summary'
require_relative 'analytics/activity'
require_relative 'analytics/files'
require_relative 'analytics/authors'
require_relative 'render/json_renderer'
require_relative 'render/console_renderer'

module PrettyGit
  # Orchestrates running a report using provider, analytics and renderer.
  class App
    def run(report, filters, out: $stdout, err: $stderr)
      _err = err # unused for now, kept for future extensibility

      ensure_repo!(filters.repo_path)

      provider = Git::Provider.new(filters)
      enum = provider.each_commit

      result = case report
               when 'summary'
                 Analytics::Summary.call(enum, filters)
               when 'activity'
                 Analytics::Activity.call(enum, filters)
               when 'authors'
                 Analytics::Authors.call(enum, filters)
               when 'files'
                 Analytics::Files.call(enum, filters)
               else
                 raise ArgumentError, "Unknown report: #{report}"
               end

      render(report, result, filters, out)
      0
    end

    private

    def ensure_repo!(path)
      return if File.directory?(File.join(path, '.git'))

      raise ArgumentError, "Not a git repository: #{path}"
    end

    def render(report, result, filters, io)
      case filters.format
      when 'console'
        Render::ConsoleRenderer.new(io: io, color: !filters.no_color).call(report, result, filters)
      else
        Render::JsonRenderer.new(io: io).call(report, result, filters)
      end
    end
  end
end
