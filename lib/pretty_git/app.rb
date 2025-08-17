# frozen_string_literal: true

require 'open3'
require_relative 'git/provider'
require_relative 'analytics/summary'
require_relative 'analytics/activity'
require_relative 'analytics/files'
require_relative 'analytics/authors'
require_relative 'analytics/heatmap'
require_relative 'analytics/languages'
require_relative 'analytics/hotspots'
require_relative 'analytics/churn'
require_relative 'analytics/ownership'
require_relative 'render/json_renderer'
require_relative 'render/console_renderer'
require_relative 'render/csv_renderer'
require_relative 'render/markdown_renderer'
require_relative 'render/yaml_renderer'
require_relative 'render/xml_renderer'

module PrettyGit
  # Orchestrates running a report using provider, analytics and renderer.
  class App
    def run(report, filters, out: $stdout, err: $stderr)
      _err = err # unused for now, kept for future extensibility

      ensure_repo!(filters.repo_path)

      provider = Git::Provider.new(filters)
      enum = provider.each_commit

      result = analytics_for(report, enum, filters)

      render(report, result, filters, out)
      0
    end

    private

    def ensure_repo!(path)
      # Use git to reliably detect work-trees/worktrees/bare repos
      stdout, _stderr, status = Open3.capture3('git', 'rev-parse', '--is-inside-work-tree', chdir: path)
      return if status.success? && stdout.to_s.strip == 'true'

      raise ArgumentError, "Not a git repository: #{path}"
    end

    def render(report, result, filters, io)
      renderer_for(filters, io).call(report, result, filters)
    end

    def renderer_for(filters, io)
      if filters.format == 'console'
        return Render::ConsoleRenderer.new(
          io: io,
          color: !filters.no_color && filters.theme != 'mono',
          theme: filters.theme
        )
      end

      dispatch = {
        'csv' => Render::CsvRenderer,
        'md' => Render::MarkdownRenderer,
        'yaml' => Render::YamlRenderer,
        'xml' => Render::XmlRenderer,
        'json' => Render::JsonRenderer
      }
      klass = dispatch[filters.format]
      raise ArgumentError, "Unknown format: #{filters.format}" unless klass

      klass.new(io: io)
    end

    def analytics_for(report, enum, filters)
      dispatch = {
        'summary' => Analytics::Summary,
        'activity' => Analytics::Activity,
        'authors' => Analytics::Authors,
        'files' => Analytics::Files,
        'heatmap' => Analytics::Heatmap,
        'languages' => Analytics::Languages,
        'hotspots' => Analytics::Hotspots,
        'churn' => Analytics::Churn,
        'ownership' => Analytics::Ownership
      }
      klass = dispatch[report]
      raise ArgumentError, "Unknown report: #{report}" unless klass

      klass.call(enum, filters)
    end
  end
end
