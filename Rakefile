# frozen_string_literal: true

require 'rake'

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
    schemas_dir = File.join(base, 'specs', 'export_schemas', 'json')
    examples_dir = File.join(base, 'specs', 'examples', 'json')

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
    xsds_dir = File.join(base, 'specs', 'export_schemas', 'xml')
    examples_dir = File.join(base, 'specs', 'examples', 'xml')

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
    sh 'bundle exec mdl -g specs'
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
        %r{^specs/},
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

task default: %i[rubocop spec]
