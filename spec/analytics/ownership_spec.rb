# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/analytics/ownership'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Ownership do
  def commit(author_name, author_email, files)
    PrettyGit::Types::Commit.new(
      sha: 's', author_name: author_name, author_email: author_email, authored_at: '2025-01-01T00:00:00Z',
      message: 'm', additions: files.sum(&:additions), deletions: files.sum(&:deletions), files: files
    )
  end

  def fs(path, addn, delt)
    PrettyGit::Types::FileStat.new(path: path, additions: addn, deletions: delt)
  end

  let(:filters) do
    PrettyGit::Filters.new(repo_path: '.', time_bucket: 'week', limit: 10, format: 'json', no_color: true)
  end

  it 'computes owner and owner_share per file based on churn' do
    # For a.txt: Alice 6 lines, Bob 4 lines => owner Alice, share 60.0
    # For b.txt: Bob 5 lines, Alice 1 line => owner Bob, share 83.33 => rounded 83.33
    commits = [
      commit('Alice', 'alice@ex', [fs('a.txt', 3, 3)]),     # a: 6
      commit('Bob', 'bob@ex',       [fs('a.txt', 2, 2)]),   # a: +4 (total a: 10)
      commit('Bob', 'bob@ex',       [fs('b.txt', 5, 0)]),   # b: 5
      commit('Alice', 'alice@ex', [fs('b.txt', 1, 0)])      # b: +1 (total b: 6)
    ]

    res = described_class.call(commits.each, filters)

    expect(res[:report]).to eq('ownership')
    items = res[:items]

    a = items.find { |i| i[:path] == 'a.txt' }
    expect(a[:owner]).to eq('Alice <alice@ex>')
    expect(a[:owner_share]).to eq(60.0)
    expect(a[:authors]).to eq(2)

    b = items.find { |i| i[:path] == 'b.txt' }
    expect(b[:owner]).to eq('Bob <bob@ex>')
    expect(b[:owner_share]).to eq(83.33)
    expect(b[:authors]).to eq(2)
  end

  it 'applies limit and sorts by owner_share desc then authors asc then path' do
    commits = [
      commit('A', 'a@ex', [fs('x.txt', 10, 0)]),    # owner_share 100
      commit('B', 'b@ex', [fs('y.txt', 3, 1)]),     # owner_share 100
      commit('A', 'a@ex', [fs('z.txt', 2, 2)]),     # owner_share 100
      commit('A', 'a@ex', [fs('x.txt', 0, 0)]),
      commit('B', 'b@ex', [fs('y.txt', 0, 0)])
    ]

    items = described_class.call(commits.each, filters.dup.tap { |f| f.limit = 2 })[:items]
    # With equal shares (100%), secondary key is authors count (all are 1), then path lexicographically
    expect(items.size).to eq(2)
    expect(items.map { |i| i[:path] }).to eq(%w[x.txt y.txt])
  end
end
