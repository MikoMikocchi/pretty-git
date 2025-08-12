# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/analytics/files'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Files do
  def commit(files)
    PrettyGit::Types::Commit.new(
      sha: 's', author_name: 'A', author_email: 'a@ex', authored_at: '2025-01-01T00:00:00Z',
      message: 'm', additions: files.sum(&:additions), deletions: files.sum(&:deletions), files: files
    )
  end

  def fs(path, addn, delt)
    PrettyGit::Types::FileStat.new(path: path, additions: addn, deletions: delt)
  end

  let(:filters) do
    PrettyGit::Filters.new(repo_path: '.', time_bucket: 'week', limit: 10, format: 'json', no_color: true)
  end

  it 'aggregates by file path and sorts by changes then commits then path' do
    commits = [
      commit([fs('a.txt', 3, 1), fs('b.txt', 2, 0)]),
      commit([fs('a.txt', 1, 1)]),
      commit([fs('c.txt', 5, 0), fs('a.txt', 0, 2)])
    ]

    result = described_class.call(commits.each, filters)

    expect(result[:report]).to eq('files')
    items = result[:items]

    # a.txt: commits=3, additions=4, deletions=4, changes=8
    # c.txt: commits=1, additions=5, deletions=0, changes=5
    # b.txt: commits=1, additions=2, deletions=0, changes=2
    expect(items.map { |i| i[:path] }).to eq(%w[a.txt c.txt b.txt])

    a = items[0]
    expect(a[:commits]).to eq(3)
    expect(a[:additions]).to eq(4)
    expect(a[:deletions]).to eq(4)
    expect(a[:changes]).to eq(8)
  end

  it 'applies limit' do
    commits = [
      commit([fs('a.txt', 1, 0)]),
      commit([fs('b.txt', 2, 0)]),
      commit([fs('c.txt', 3, 0)])
    ]

    limited = described_class.call(commits.each, filters.dup.tap { |f| f.limit = 2 })
    expect(limited[:items].size).to eq(2)
  end
end
