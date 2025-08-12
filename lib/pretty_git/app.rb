# frozen_string_literal: true

require_relative 'git/provider'
require_relative 'analytics/summary'
require_relative 'analytics/activity'
require_relative 'analytics/files'
require_relative 'analytics/authors'
require_relative 'analytics/heatmap'
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

      result = case report
               when 'summary'
                 Analytics::Summary.call(enum, filters)
               when 'activity'
                 Analytics::Activity.call(enum, filters)
               when 'authors'
                 Analytics::Authors.call(enum, filters)
               when 'files'
                 Analytics::Files.call(enum, filters)
               when 'heatmap'
                 Analytics::Heatmap.call(enum, filters)
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
      renderer_for(filters, io).call(report, result, filters)
    end

    def renderer_for(filters, io)
      case filters.format
      when 'console'
        use_color = !filters.no_color && filters.theme != 'mono'
        Render::ConsoleRenderer.new(io: io, color: use_color, theme: filters.theme)
      when 'csv'
        Render::CsvRenderer.new(io: io)
      when 'md'
        Render::MarkdownRenderer.new(io: io)
      when 'yaml'
        Render::YamlRenderer.new(io: io)
      when 'xml'
        Render::XmlRenderer.new(io: io)
      else
        Render::JsonRenderer.new(io: io)
      end
    end
  end
end
