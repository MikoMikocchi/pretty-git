# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/analytics/hotspots'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Hotspots do
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

  it 'aggregates per file, computes score=commits*(adds+dels), and sorts as specified' do
    # Build commits so that ordering by score, then commits, then changes, then path is exercised
    # a.txt: commits=2, adds=3, dels=1 => changes=4, score=8
    # b.txt: commits=2, adds=2, dels=1 => changes=3, score=6
    # c.txt: commits=1, adds=10, dels=0 => changes=10, score=10 (should be first)
    commits = [
      commit([fs('a.txt', 3, 1), fs('b.txt', 2, 0)]),
      commit([fs('a.txt', 0, 0), fs('b.txt', 0, 1)]),
      commit([fs('c.txt', 10, 0)])
    ]

    result = described_class.call(commits.each, filters)

    expect(result[:report]).to eq('hotspots')
    expect(result[:repo_path]).to be_a(String)
    expect(result[:period]).to include(:since, :until)
    expect(result[:generated_at]).to be_a(String)

    items = result[:items]
    expect(items.map { |i| i[:path] }).to eq(%w[c.txt a.txt b.txt])

    c = items[0]
    expect(c[:commits]).to eq(1)
    expect(c[:additions]).to eq(10)
    expect(c[:deletions]).to eq(0)
    expect(c[:score]).to eq(10)

    a = items[1]
    expect(a[:commits]).to eq(2)
    expect(a[:additions]).to eq(3)
    expect(a[:deletions]).to eq(1)
    expect(a[:score]).to eq(8)
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
