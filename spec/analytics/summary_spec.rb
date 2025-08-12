# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/analytics/summary'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Summary do
  def file(path, adds, dels)
    PrettyGit::Types::FileStat.new(path: path, additions: adds, deletions: dels)
  end

  def commit(attrs = {})
    files = Array(attrs.delete(:files))
    files = [file('a.rb', 1, 0)] if files.empty?
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

  def filters(limit: 10)
    PrettyGit::Filters.new(
      repo_path: '.', branches: nil, since: nil, until: nil,
      authors: nil, exclude_authors: nil, paths: nil, exclude_paths: nil,
      time_bucket: 'week', limit: limit, format: 'json', out: nil, no_color: true
    )
  end

  it 'computes totals and top authors/files' do
    commits = [
      commit(author_name: 'A', files: [file('x.rb', 3, 1)]),
      commit(author_name: 'B', files: [file('y.rb', 5, 0)]),
      commit(author_name: 'A', files: [file('x.rb', 1, 2)])
    ]

    result = described_class.call(commits.each, filters(limit: 10))

    expect(result[:report]).to eq('summary')
    t = result[:totals]
    expect(t[:commits]).to eq(3)
    expect(t[:authors]).to eq(2)
    expect(t[:additions]).to eq(9)
    expect(t[:deletions]).to eq(3)

    top_authors = result[:top_authors]
    expect(top_authors.first[:author]).to eq('A')
    expect(top_authors.first[:commits]).to eq(2)

    top_files = result[:top_files]
    expect(top_files.first[:path]).to eq('x.rb')
    expect(top_files.first[:changes]).to eq(7) # (3+1)+(1+2)
  end

  it 'applies limit to tops' do
    commits = 5.times.map { |i| commit(author_name: "A#{i}") }
    res = described_class.call(commits.each, filters(limit: 3))
    expect(res[:top_authors].length).to eq(3)
    expect(res[:top_files].length).to be <= 3
  end
end
