# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../lib/pretty_git/analytics/authors'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Authors do
  def commit(attrs = {})
    files = Array(attrs.delete(:files))
    files = [PrettyGit::Types::FileStat.new(path: 'a.txt', additions: 1, deletions: 0)] if files.empty?
    PrettyGit::Types::Commit.new(
      {
        sha: attrs[:sha] || 's',
        author_name: attrs[:author_name] || 'John',
        author_email: attrs[:author_email] || 'john@example.com',
        authored_at: attrs[:authored_at] || '2025-01-01T00:00:00Z',
        message: attrs[:message] || 'msg',
        additions: files.sum(&:additions),
        deletions: files.sum(&:deletions),
        files: files
      }
    )
  end

  def filters(opts = {})
    PrettyGit::Filters.new(
      {
        repo_path: opts[:repo_path] || '.',
        branches: nil,
        since: opts[:since],
        until: opts[:until],
        authors: nil,
        exclude_authors: nil,
        paths: nil,
        exclude_paths: nil,
        time_bucket: 'week',
        limit: opts[:limit],
        format: 'json',
        out: nil,
        no_color: true
      }
    )
  end

  it 'aggregates by authors and sorts by commits/additions' do
    commits = [
      commit(author_name: 'A', author_email: 'a@ex', files: [
        PrettyGit::Types::FileStat.new(path: 'x', additions: 3, deletions: 1)
      ]),
      commit(author_name: 'B', author_email: 'b@ex', files: [
        PrettyGit::Types::FileStat.new(path: 'y', additions: 5, deletions: 0)
      ]),
      commit(author_name: 'A', author_email: 'a@ex', files: [
        PrettyGit::Types::FileStat.new(path: 'z', additions: 1, deletions: 2)
      ])
    ]

    result = described_class.call(commits.each, filters(limit: 10))

    expect(result[:report]).to eq('authors')
    expect(result[:period]).to include(:since, :until)
    expect(result[:totals]).to include(:authors, :commits, :additions, :deletions)

    items = result[:items]
    expect(items.size).to eq(2)
    # B: 1 commit, additions 5 -> avg 5.0; A: 2 commits, additions 4, deletions 3 -> avg 3.5
    expect(items.first[:author]).to eq('A')
    expect(items.first[:commits]).to eq(2)
    expect(items.first[:avg_commit_size]).to be_within(0.01).of(3.5)
  end

  it 'applies limit' do
    commits = [
      commit(author_name: 'A', author_email: 'a@ex'),
      commit(author_name: 'B', author_email: 'b@ex'),
      commit(author_name: 'C', author_email: 'c@ex')
    ]

    items = described_class.call(commits.each, filters(limit: 2))[:items]
    expect(items.length).to eq(2)
  end
end
