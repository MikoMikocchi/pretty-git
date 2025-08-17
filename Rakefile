# frozen_string_literal: true

require 'rake'
require 'rbconfig'
require 'shellwords'

desc 'Run rubocop'
task :rubocop do
  sh 'bundle exec rubocop'
end
desc 'Run specs'
task :spec do
  sh 'bundle exec rspec'
end

# rubocop:disable Metrics/BlockLength
namespace :validate do
  desc 'Validate JSON examples against JSON Schemas'
  task :json do
    require 'json'
    require 'json_schemer'
    base = File.expand_path(__dir__)
    schemas_dir = File.join(base, 'docs', 'export_schemas', 'json')
    examples_dir = File.join(base, 'docs', 'examples', 'json')

    mapping = {
      'hotspots.json' => File.join(schemas_dir, 'hotspots.schema.json'),
      'churn.json' => File.join(schemas_dir, 'churn.schema.json'),
      'ownership.json' => File.join(schemas_dir, 'ownership.schema.json'),
      'languages.json' => File.join(schemas_dir, 'languages.schema.json')
    }

    failures = []
    mapping.each do |example_name, schema_path|
      example_path = File.join(examples_dir, example_name)
      next unless File.exist?(example_path)

      schema = JSON.parse(File.read(schema_path))
      schemer = JSONSchemer.schema(schema)
      data = JSON.parse(File.read(example_path))
      errors = schemer.validate(data).to_a
      unless errors.empty?
        failures << "JSON validation failed for #{example_name}:\n  - #{errors.map(&:to_s).join("\n  - ")}"
      end
    end

    if failures.empty?
      puts 'JSON validation passed'
    else
      abort failures.join("\n\n")
    end
  end

  desc 'Validate XML examples against XSD Schemas'
  task :xml do
    require 'nokogiri'
    base = File.expand_path(__dir__)
    xsds_dir = File.join(base, 'docs', 'export_schemas', 'xml')
    examples_dir = File.join(base, 'docs', 'examples', 'xml')

    mapping = {
      'hotspots.xml' => File.join(xsds_dir, 'hotspots.xsd'),
      'churn.xml' => File.join(xsds_dir, 'churn.xsd'),
      'ownership.xml' => File.join(xsds_dir, 'ownership.xsd'),
      'languages.xml' => File.join(xsds_dir, 'languages.xsd')
    }

    failures = []
    mapping.each do |example_name, xsd_path|
      example_path = File.join(examples_dir, example_name)
      next unless File.exist?(example_path)

      xsd = Nokogiri::XML::Schema(File.read(xsd_path))
      doc = Nokogiri::XML(File.read(example_path))
      errors = xsd.validate(doc)
      unless errors.empty?
        failures << "XML validation failed for #{example_name}:\n  - #{errors.map(&:to_s).join("\n  - ")}"
      end
    end

    if failures.empty?
      puts 'XML validation passed'
    else
      abort failures.join("\n\n")
    end
  end
end

# rubocop:enable Metrics/BlockLength

namespace :lint do
  desc 'Markdown lint (mdl)'
  task :markdown do
    # Use local .mdlrc as STYLE (-s) so rule excludes apply (mdl 0.13.0)
    mdl_style = File.expand_path('.mdlrc', __dir__)
    sh "bundle exec mdl -s #{mdl_style} docs"
  end
end

# rubocop:disable Metrics/BlockLength
namespace :release do
  desc 'Build gem and verify packaged files do not contain internal docs/configs'
  task :check_gem_files do
    require 'tmpdir'
    require 'fileutils'

    gemspec = 'pretty-git.gemspec'
    sh "gem build #{gemspec}"

    gem_file = Dir['pretty-git-*.gem'].max_by { |f| File.mtime(f) }
    abort 'Gem file not found after build' unless gem_file

    Dir.mktmpdir('gem_check_') do |dir|
      sh "gem unpack #{gem_file} --target #{dir}"
      unpacked_root = Dir[File.join(dir, 'pretty-git-*')].first
      abort 'Unpacked gem dir not found' unless unpacked_root

      # Collect relative paths
      files = Dir.chdir(unpacked_root) { Dir['**/*'].select { |p| File.file?(File.join(unpacked_root, p)) } }

      disallowed = [
        %r{^(spec|docs)/},
        %r{^\.github/},
        /^\.mdlrc$/,
        /^\.markdownlint\.yml$/,
        /^lychee\.toml$/,
        /^\.gitattributes$/,
        /^\.gitignore$/
      ]

      offenders = files.select do |path|
        disallowed.any? { |pat| path.match?(pat) }
      end

      if offenders.any?
        abort "Gem contains disallowed files:\n  - #{offenders.join("\n  - ")}"
      else
        puts 'Gem content check passed'
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength

namespace :spec do
  desc 'Run only golden files specs (YAML/JSON/XML/CSV)'
  task :golden do
    sh 'bundle exec rspec spec/integration/*golden_files*'
  end

  desc 'Regenerate golden files (writes fixtures)'
  task 'golden:update' do
    sh 'UPDATE_GOLDEN=1 bundle exec rspec spec/integration/*golden_files*'
  end
end

# Performance tasks
namespace :perf do
  desc 'Run perf baseline. Usage: rake perf:baseline REPO=path REPORTS="summary,files" FORMAT=console ITERS=3'
  task :baseline do
    repo = File.expand_path(ENV['REPO'] || '.', Dir.pwd)
    reports = ENV['REPORTS'] || 'summary,files,authors,languages,activity,heatmap,hotspots,churn,ownership'
    format = ENV['FORMAT'] || 'console'
    iters = (ENV['ITERS'] || '3').to_i
    since = ENV.fetch('SINCE', nil)
    until_at = ENV.fetch('UNTIL', nil)
    allocs = ENV.fetch('ALLOCS', nil)
    extra = ENV.fetch('PERF_ARGS', nil)

    ruby = RbConfig.ruby
    script = File.expand_path(File.join(__dir__, 'scripts', 'perf_baseline.rb'))
    args = [ruby, script, '--repo', repo, '--reports', reports, '--format', format, '--iters', iters.to_s]
    args += ['--since', since] if since
    args += ['--until', until_at] if until_at
    args << '--allocs' if allocs && allocs != '0' && allocs.downcase != 'false'
    args += Shellwords.split(extra) if extra && !extra.strip.empty?

    sh Shellwords.shelljoin(args)
  end
end

task default: %i[rubocop spec]
