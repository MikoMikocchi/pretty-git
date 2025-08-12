# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require_relative '../../../lib/pretty_git/render/csv_renderer'

RSpec.describe PrettyGit::Render::CsvRenderer do
  let(:io) { StringIO.new }

  it 'renders activity CSV with correct headers and rows' do
    data = {
      report: 'activity',
      items: [
        { bucket: 'week', timestamp: '2025-06-02T00:00:00Z', commits: 120, additions: 3456, deletions: 2100 },
        { bucket: 'week', timestamp: '2025-06-09T00:00:00Z', commits: 98, additions: 2890, deletions: 1760 }
      ]
    }

    described_class.new(io: io).call('activity', data, nil)

    lines = io.string.lines.map(&:chomp)
    expect(lines.first).to eq('bucket,timestamp,commits,additions,deletions')
    expect(lines[1]).to eq('week,2025-06-02T00:00:00Z,120,3456,2100')
    expect(lines[2]).to eq('week,2025-06-09T00:00:00Z,98,2890,1760')
  end

  it 'renders files CSV with correct headers and rows' do
    data = {
      report: 'files',
      items: [
        { path: 'a.txt', commits: 3, additions: 4, deletions: 4, changes: 8 },
        { path: 'b.txt', commits: 1, additions: 2, deletions: 0, changes: 2 }
      ]
    }

    described_class.new(io: io).call('files', data, nil)

    lines = io.string.lines.map(&:chomp)
    expect(lines.first).to eq('path,commits,additions,deletions,changes')
    expect(lines[1]).to eq('a.txt,3,4,4,8')
    expect(lines[2]).to eq('b.txt,1,2,0,2')
  end
end
