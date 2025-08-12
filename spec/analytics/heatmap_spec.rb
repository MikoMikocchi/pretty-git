# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/pretty_git/analytics/heatmap'
require_relative '../../lib/pretty_git/types'
require_relative '../../lib/pretty_git/filters'

RSpec.describe PrettyGit::Analytics::Heatmap do
  def commit_at(iso_time)
    PrettyGit::Types::Commit.new(
      sha: 's', author_name: 'A', author_email: 'a@ex', authored_at: iso_time,
      message: 'm', additions: 1, deletions: 0, files: []
    )
  end

  let(:filters) do
    PrettyGit::Filters.new(repo_path: '.', time_bucket: 'week', limit: 0, format: 'json', no_color: true)
  end

  it 'aggregates commits by day-of-week (Mon=1..Sun=7) and hour (0..23)' do
    commits = [
      # 2025-01-06 is Monday. 10:15 and 10:45 should aggregate to dow=1,hour=10
      commit_at('2025-01-06T10:15:00Z'),
      commit_at('2025-01-06T10:45:00Z'),
      # Sunday (wday=0 => dow=7), 23h
      commit_at('2025-01-05T23:00:00Z')
    ]

    result = described_class.call(commits.each, filters)

    expect(result[:report]).to eq('heatmap')
    items = result[:items]

    # Find Monday 10h bucket
    mon10 = items.find { |i| i[:dow] == 1 && i[:hour] == 10 }
    expect(mon10).not_to be_nil
    expect(mon10[:commits]).to eq(2)

    # Find Sunday 23h bucket
    sun23 = items.find { |i| i[:dow] == 7 && i[:hour] == 23 }
    expect(sun23).not_to be_nil
    expect(sun23[:commits]).to eq(1)

    # Ensure ordering by dow asc, hour asc
    sorted = items.sort_by { |i| [i[:dow], i[:hour]] }
    expect(items).to eq(sorted)
  end

  it 'returns empty items when there are no commits' do
    result = described_class.call([].each, filters)
    expect(result[:items]).to eq([])
  end
end
