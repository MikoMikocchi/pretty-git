# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tempfile'
require 'fileutils'
require_relative '../../lib/pretty_git/cli'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::CLI do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def parse_and_run(argv)
    described_class.run(argv.dup, out: out, err: err)
  end

  it 'warns that --theme has no effect when format is non-console' do
    code = parse_and_run(['summary', '--format', 'json', '--theme', 'bright'])
    expect(code).to eq(0)
    expect(err.string).to include('Warning: --theme has no effect when --format=json')
  end

  it 'warns that --no-color has no effect when format is non-console' do
    code = parse_and_run(['summary', '--format', 'csv', '--no-color'])
    expect(code).to eq(0)
    expect(err.string).to include('Warning: --no-color has no effect when --format=csv')
  end

  it 'returns 1 for invalid --theme value' do
    code = parse_and_run(['authors', '--theme', 'neon'])
    expect(code).to eq(1)
    expect(err.string).to include('Unknown theme: neon')
  end

  it 'passes --theme to Filters' do
    app_double = instance_double(PrettyGit::App)
    allow(PrettyGit::App).to receive(:new).and_return(app_double)
    captured_filters = nil
    allow(app_double).to receive(:run) do |_report, filters, out:, err:|
      _ = out
      _ = err
      captured_filters = filters
      0
    end

    code = parse_and_run(['summary', '--theme', 'bright'])
    expect(code).to eq(0)
    expect(captured_filters).to be_a(PrettyGit::Filters)
    expect(captured_filters.theme).to eq('bright')
  end

  it 'prints version and exits 0 with --version' do
    code = parse_and_run(['--version'])
    expect(code).to eq(0)
    expect(out.string.strip).to eq(PrettyGit::VERSION)
  end

  it 'prints help and exits 0 with --help' do
    code = parse_and_run(['--help'])
    expect(code).to eq(0)
    expect(out.string).to include('Usage: pretty-git')
  end

  it 'returns 1 and prints error for unknown report' do
    code = parse_and_run(['unknown-report'])
    expect(code).to eq(1)
    expect(err.string).to include('Unknown report: unknown-report')
  end

  it 'returns 1 for invalid --limit value' do
    code = parse_and_run(['--limit', 'NaN'])
    expect(code).to eq(1)
    expect(err.string).to match(/Invalid --limit/i)
  end

  it 'passes parsed repository and filters to App.run (branches, authors, paths)' do
    app_double = instance_double(PrettyGit::App)
    allow(PrettyGit::App).to receive(:new).and_return(app_double)
    captured_filters = nil
    allow(app_double).to receive(:run) do |_report, filters, out:, err:|
      _ = out
      _ = err
      captured_filters = filters
      0
    end

    code = parse_and_run([
      'authors',
      '--repo', '/repo',
      '--branch', 'main', '--branch', 'dev',
      '--author', 'alice', '--exclude-author', 'bot',
      '--path', 'app/**/*.rb', '--exclude-path', 'spec/**'
    ])

    expect(code).to eq(0)
    expect(app_double).to have_received(:run)
    expect(captured_filters).to be_a(PrettyGit::Filters)
    expect(captured_filters.repo_path).to eq('/repo')
    expect(captured_filters.branches).to eq(%w[main dev])
    expect(captured_filters.authors).to eq(['alice'])
    expect(captured_filters.exclude_authors).to eq(['bot'])
    expect(captured_filters.paths).to eq(['app/**/*.rb'])
    expect(captured_filters.exclude_paths).to eq(['spec/**'])
  end

  it "normalizes limit 'all' to 0 and sets format/no_color/time_bucket" do
    app_double = instance_double(PrettyGit::App)
    allow(PrettyGit::App).to receive(:new).and_return(app_double)
    captured = {}
    allow(app_double).to receive(:run) do |report, filters, out:, err:|
      captured[:report] = report
      captured[:filters] = filters
      captured[:out] = out
      captured[:err] = err
      0
    end

    code = parse_and_run([
      'authors', '--time-bucket', 'week', '--limit', 'all', '--format', 'json', '--no-color'
    ])

    expect(code).to eq(0)
    expect(app_double).to have_received(:run)
    expect(captured[:report]).to eq('authors')
    f = captured[:filters]
    expect(f.limit).to eq(0)
    expect(f.format).to eq('json')
    expect(f.time_bucket).to eq('week')
    expect(f.no_color).to be true
  end

  it 'writes to file when --out is provided' do
    file = Tempfile.new('pg-out')
    file_path = file.path
    file.close!

    app_double = instance_double(PrettyGit::App)
    allow(PrettyGit::App).to receive(:new).and_return(app_double)
    allow(app_double).to receive(:run) do |report, _filters, out:, err:|
      expect(report).to eq('summary')
      # simulate renderer writing
      out.write('{"ok":true}')
      _ = err
      0
    end

    code = described_class.run(['--out', file_path], out: out, err: err)
    expect(code).to eq(0)
    content = File.read(file_path)
    expect(content).to include('"ok":true')
  ensure
    FileUtils.rm_f(file_path)
  end

  it 'lists --theme and --metric in --help' do
    code = parse_and_run(['--help'])
    expect(code).to eq(0)
    txt = out.string
    expect(txt).to include('--theme')
    expect(txt).to include('--metric')
    expect(txt).to include('--verbose')
  end

  it 'returns 1 when --metric is used with non-languages report' do
    code = parse_and_run(['authors', '--metric', 'bytes'])
    expect(code).to eq(1)
    expect(err.string).to include("--metric is only supported for 'languages' report")
  end

  it 'passes --verbose to Filters' do
    app_double = instance_double(PrettyGit::App)
    allow(PrettyGit::App).to receive(:new).and_return(app_double)
    captured_filters = nil
    allow(app_double).to receive(:run) do |_report, filters, out:, err:|
      _ = out
      _ = err
      captured_filters = filters
      0
    end

    code = parse_and_run(['summary', '--verbose'])
    expect(code).to eq(0)
    expect(captured_filters).to be_a(PrettyGit::Filters)
    expect(captured_filters.verbose).to be true
  end
end
