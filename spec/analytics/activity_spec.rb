# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/analytics/activity'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Activity do
  let(:filters_week) do
    PrettyGit::Filters.new(
      repo_path: '.',
      time_bucket: 'week',
      limit: 10,
      format: 'json'
    )
  end

  def commit(attrs = {})
    PrettyGit::Types::Commit.new(
      sha: attrs[:sha] || 'x',
      author_name: attrs[:author] || 'A',
      author_email: attrs[:email] || 'a@example.com',
      authored_at: attrs[:time] || '2025-06-02T00:00:00Z',
      message: attrs[:message] || 'm',
      additions: attrs[:additions] || 0,
      deletions: attrs[:deletions] || 0,
      files: attrs[:files] || []
    )
  end

  it 'creates buckets by ISO week starting Monday' do
    enum = [
      commit(time: '2025-06-02T10:00:00Z', additions: 5, deletions: 1),
      commit(time: '2025-06-03T12:00:00Z', additions: 3, deletions: 2),
      commit(time: '2025-06-08T23:59:59Z', additions: 2, deletions: 2),
      commit(time: '2025-06-09T00:00:01Z', additions: 7, deletions: 0)
    ]

    result = described_class.call(enum, filters_week)

    expect(result[:report]).to eq('activity')
    expect(result[:bucket]).to eq('week')
    expect(result[:items].map { |i| i[:timestamp] }).to eq([
      '2025-06-02T00:00:00Z',
      '2025-06-09T00:00:00Z'
    ])
  end

  it 'sums totals per bucket' do
    enum = [
      commit(time: '2025-06-02T10:00:00Z', additions: 5, deletions: 1),
      commit(time: '2025-06-03T12:00:00Z', additions: 3, deletions: 2),
      commit(time: '2025-06-08T23:59:59Z', additions: 2, deletions: 2)
    ]

    result = described_class.call(enum, filters_week)

    first = result[:items].first
    expect(first).to include(
      timestamp: '2025-06-02T00:00:00Z', commits: 3, additions: 10, deletions: 5
    )
  end

  it 'supports day bucket' do
    filters = filters_week.dup
    filters.time_bucket = 'day'

    enum = [
      commit(time: '2025-06-02T10:00:00Z', additions: 5, deletions: 1),
      commit(time: '2025-06-02T12:00:00Z', additions: 2, deletions: 3)
    ]
    result = described_class.call(enum, filters)

    expect(result[:bucket]).to eq('day')
    expect(result[:items].size).to eq(1)
    expect(result[:items][0][:timestamp]).to eq('2025-06-02T00:00:00Z')
    expect(result[:items][0][:additions]).to eq(7)
    expect(result[:items][0][:deletions]).to eq(4)
  end

  it 'supports month bucket' do
    filters = filters_week.dup
    filters.time_bucket = 'month'

    enum = [
      commit(time: '2025-06-30T23:59:00Z', additions: 1, deletions: 1),
      commit(time: '2025-06-01T00:00:00Z', additions: 2, deletions: 3)
    ]
    result = described_class.call(enum, filters)

    expect(result[:bucket]).to eq('month')
    expect(result[:items].size).to eq(1)
    expect(result[:items][0][:timestamp]).to eq('2025-06-01T00:00:00Z')
    expect(result[:items][0][:commits]).to eq(2)
    expect(result[:items][0][:additions]).to eq(3)
    expect(result[:items][0][:deletions]).to eq(4)
  end
end
