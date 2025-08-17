# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../../lib/pretty_git/git/provider'
require_relative '../../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Git::Provider do
  let(:us) { "\x1F" } # unit separator
  let(:rs) { "\x1E" } # record separator
  let(:wait_thr_success) do
    instance_double(Process::Waiter, value: instance_double(Process::Status, success?: true, exitstatus: 0))
  end

  let(:wait_thr_fail) do
    instance_double(Process::Waiter, value: instance_double(Process::Status, success?: false, exitstatus: 128))
  end

  let(:filters) do
    PrettyGit::Filters.new(
      repo_path: '.',
      branches: ['main'],
      authors: ['John'],
      exclude_authors: [],
      paths: ['lib/'],
      exclude_paths: [],
      since: '2025-01-01T00:00:00Z',
      until_at: '2025-02-01T00:00:00Z',
      time_bucket: 'week',
      limit: 10,
      format: 'json',
      out: nil,
      no_color: false
    )
  end

  def stdout_with_commits(lines)
    StringIO.new("#{lines.join("\n")}\n")
  end

  describe '#each_commit' do
    it 'parses commits and aggregates file stats' do
      header = [
        'deadbeef', 'John Doe', 'john@example.com', '2025-01-02T03:04:05Z', 'Initial commit'
      ].join(us)
      num1 = ['10', '2', 'README.md'].join("\t")
      num2 = ['-', '5', 'lib/file.rb'].join("\t") # binary-style deletions, additions as '-'

      lines = [header, num1, num2, rs]
      stdout = stdout_with_commits(lines)

      allow(Open3).to receive(:popen3).and_yield(
        instance_double(IO), stdout, instance_double(IO, read: ''), wait_thr_success
      )

      enum = described_class.new(filters).each_commit
      commits = enum.to_a
      expect(commits.size).to eq(1)

      c = commits.first
      expect(c.sha).to eq('deadbeef')
      expect(c.author_name).to eq('John Doe')
      expect(c.author_email).to eq('john@example.com')
      expect(c.authored_at).to eq('2025-01-02T03:04:05Z')
      expect(c.message).to eq('Initial commit')
      expect(c.additions).to eq(10)
      expect(c.deletions).to eq(7) # 2 + 5
      expect(c.files.map(&:path)).to contain_exactly('README.md', 'lib/file.rb')
    end

    it 'passes filters as git arguments' do
      stdout = stdout_with_commits([rs])
      captured_cmd = nil

      allow(Open3).to receive(:popen3) do |*cmd, chdir:, &blk|
        captured_cmd = cmd
        expect(chdir).to eq('.')
        i = instance_double(IO)
        o = stdout
        e = instance_double(IO, read: '')
        w = wait_thr_success
        blk.call(i, o, e, w)
      end

      described_class.new(filters).each_commit.to_a

      # Ensure important flags are present
      expect(captured_cmd).to include('git', 'log', '--no-merges', '--date=iso-strict', '--numstat')
      expect(captured_cmd.any? { |a| a.start_with?('--since=2025-01-01') }).to be true
      expect(captured_cmd.any? { |a| a.start_with?('--until=2025-02-01') }).to be true
      expect(captured_cmd).to include('--author=John')
      # Branches are passed as explicit revisions before '--'
      idx = captured_cmd.index('--')
      expect(idx).not_to be_nil
      expect(captured_cmd[0...idx]).to include('main')
      # Paths are added after --
      expect(captured_cmd[(idx + 1)..]).to include('lib/')
    end

    it 'raises with stderr when git fails' do
      stdout = stdout_with_commits([])
      stderr = instance_double(IO, read: 'fatal: not a git repository')

      allow(Open3).to receive(:popen3).and_yield(
        instance_double(IO), stdout, stderr, wait_thr_fail
      )

      expect do
        described_class.new(filters).each_commit.first
      end.to raise_error(StandardError, /fatal: not a git repository/)
    end

    it 'skips commits by excluded authors' do
      header = [
        'beadface', 'CI Bot', 'bot@example.com', '2025-01-05T00:00:00Z', 'Bot commit'
      ].join(us)
      num = ['1', '0', 'README.md'].join("\t")
      lines = [header, num, rs]
      stdout = stdout_with_commits(lines)

      allow(Open3).to receive(:popen3).and_yield(
        instance_double(IO), stdout, instance_double(IO, read: ''), wait_thr_success
      )

      f = filters.dup
      f.exclude_authors = ['bot']

      commits = described_class.new(f).each_commit.to_a
      expect(commits).to be_empty
    end

    it 'adds pathspec excludes and includes . when only excludes are provided' do
      stdout = stdout_with_commits([rs])
      captured_cmd = nil

      allow(Open3).to receive(:popen3) do |*cmd, chdir:, &blk|
        captured_cmd = cmd
        _ = chdir
        blk.call(instance_double(IO), stdout, instance_double(IO, read: ''), wait_thr_success)
      end

      f = filters.dup
      f.paths = []
      f.exclude_paths = ['node_modules/**', 'vendor/**']

      described_class.new(f).each_commit.to_a

      idx = captured_cmd.index('--')
      expect(idx).not_to be_nil
      tail = captured_cmd[(idx + 1)..]
      expect(tail).to include('.')
      expect(tail).to include(':(exclude,glob)node_modules/**')
      expect(tail).to include(':(exclude,glob)vendor/**')
    end

    it 'logs git command to stderr when verbose is enabled' do
      stdout = stdout_with_commits([rs])
      allow(Open3).to receive(:popen3).and_yield(
        instance_double(IO), stdout, instance_double(IO, read: ''), wait_thr_success
      )

      verbose_filters = filters.dup
      verbose_filters.verbose = true

      expect do
        described_class.new(verbose_filters).each_commit.to_a
      end.to output(/\[pretty-git\] git cmd: .*git log/).to_stderr
    end
  end
end
